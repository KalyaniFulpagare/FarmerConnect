const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {
  getFirestore,
  FieldValue,
} = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

initializeApp();

const db = getFirestore();

const STATUS_FLOW = [
  "placed",
  "confirmed",
  "packed",
  "out_for_delivery",
  "delivered",
];

async function createNotification(transaction, userId, title, body) {
  const ref = db.collection("notifications").doc();

  transaction.set(ref, {
    id: ref.id,
    userId,
    title,
    body,
    isRead: false,
    createdAt: FieldValue.serverTimestamp(),
  });
}

exports.placeOrder = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in.");
  }

  const data = request.data || {};

  const {
    orderId,
    productId,
    quantity,
    totalPrice,
    deliveryAddress,
  } = data;

  if (
    typeof orderId !== "string" ||
    typeof productId !== "string" ||
    typeof quantity !== "number" ||
    typeof totalPrice !== "number" ||
    typeof deliveryAddress !== "string"
  ) {
    throw new HttpsError("invalid-argument", "Invalid order data.");
  }

  if (
    !orderId.trim() ||
    !productId.trim() ||
    !Number.isFinite(quantity) ||
    !Number.isFinite(totalPrice) ||
    quantity <= 0 ||
    totalPrice < 0 ||
    !deliveryAddress.trim()
  ) {
    throw new HttpsError("invalid-argument", "Invalid order values.");
  }

  const productRef = db.collection("products").doc(productId);
  const orderRef = db.collection("orders").doc(orderId);

  await db.runTransaction(async (transaction) => {
    const productSnap = await transaction.get(productRef);
    const existingOrderSnap = await transaction.get(orderRef);

    if (existingOrderSnap.exists) {
      const existingOrder = existingOrderSnap.data();

      if (existingOrder.buyerId !== request.auth.uid) {
        throw new HttpsError("already-exists", "This order ID is already in use.");
      }

      if (
        existingOrder.productId !== productId ||
        Number(existingOrder.quantity) !== quantity
      ) {
        throw new HttpsError("already-exists", "This order ID belongs to another order.");
      }

      return;
    }

    if (!productSnap.exists) {
      throw new HttpsError("not-found", "This product is no longer available.");
    }

    const product = productSnap.data();

    if (product.sellerId === request.auth.uid) {
      throw new HttpsError("permission-denied", "You cannot order your own product.");
    }

    const currentQuantity = Number(product.quantity || 0);
    const price = Number(product.price || 0);

    if (
      !product.isActive ||
      currentQuantity <= 0 ||
      !Number.isFinite(price) ||
      price < 0
    ) {
      throw new HttpsError("failed-precondition", "This product is out of stock.");
    }

    if (quantity > currentQuantity) {
      throw new Error(
        `Only ${currentQuantity} ${product.unit || ""} available.`,
      );
    }

    const expectedTotal = price * quantity;

    if (Math.abs(totalPrice - expectedTotal) > 0.01) {
      throw new Error(
        "Order total does not match the current product price.",
      );
    }

    const newQuantity = currentQuantity - quantity;

    transaction.update(productRef, {
      quantity: newQuantity,
      isActive: newQuantity > 0,
    });

    transaction.set(orderRef, {
      id: orderId,
      buyerId: request.auth.uid,
      sellerId: product.sellerId,
      productId,
      productName: product.name,
      quantity,
      totalPrice: expectedTotal,
      status: "placed",
      deliveryAddress: deliveryAddress.trim(),
      createdAt: FieldValue.serverTimestamp(),
    });

    await createNotification(
      transaction,
      request.auth.uid,
      "Order placed",
      `${product.name} order placed successfully.`,
    );

    await createNotification(
      transaction,
      product.sellerId,
      "New order",
      `You received a new order for ${product.name}.`,
    );
  });

  return {
    success: true,
    orderId,
  };
});


exports.placeCartOrder = onCall(async (request) => {
  if (!request.auth) {
    throw new Error("You must be logged in.");
  }

  const data = request.data || {};
  const items = data.items;
  const deliveryAddress = data.deliveryAddress;

  if (
    !Array.isArray(items) ||
    items.length === 0 ||
    items.length > 20 ||
    typeof deliveryAddress !== "string" ||
    !deliveryAddress.trim()
  ) {
    throw new Error("Invalid cart checkout data.");
  }

  if (items.some((item) => item == null || typeof item !== "object" || Array.isArray(item))) {
    throw new Error("Invalid cart item.");
  }

  const normalizedItems = items.map((item) => ({
    orderId: item.orderId,
    productId: item.productId,
    quantity: Number(item.quantity),
  }));

  for (const item of normalizedItems) {
    if (
      typeof item.orderId !== "string" ||
      !item.orderId.trim() ||
      typeof item.productId !== "string" ||
      !item.productId.trim() ||
      !Number.isFinite(item.quantity) ||
      item.quantity <= 0
    ) {
      throw new Error("Invalid cart item.");
    }
  }

  const orderIds = new Set();
  const productIds = new Set();

  for (const item of normalizedItems) {
    if (orderIds.has(item.orderId)) {
      throw new Error("Duplicate order ID.");
    }

    if (productIds.has(item.productId)) {
      throw new Error("Duplicate product in cart.");
    }

    orderIds.add(item.orderId);
    productIds.add(item.productId);
  }

  const productRefs = normalizedItems.map((item) =>
    db.collection("products").doc(item.productId)
  );

  const orderRefs = normalizedItems.map((item) =>
    db.collection("orders").doc(item.orderId)
  );

  await db.runTransaction(async (transaction) => {
    const productSnaps = [];

    for (const ref of productRefs) {
      productSnaps.push(await transaction.get(ref));
    }

    const orderSnaps = [];

    for (const ref of orderRefs) {
      orderSnaps.push(await transaction.get(ref));
    }

    const products = [];

    for (let i = 0; i < normalizedItems.length; i++) {
      const item = normalizedItems[i];
      const productSnap = productSnaps[i];
      const orderSnap = orderSnaps[i];

      if (orderSnap.exists) {
        const existingOrder = orderSnap.data();

        if (
          existingOrder.buyerId !== request.auth.uid ||
          existingOrder.productId !== item.productId ||
          Number(existingOrder.quantity) !== item.quantity
        ) {
          throw new Error(
            `Order ${item.orderId} already exists with different data.`
          );
        }

        products.push(null);
        continue;
      }

      if (!productSnap.exists) {
        throw new Error("One or more products are no longer available.");
      }

      const product = productSnap.data();

      if (product.sellerId === request.auth.uid) {
        throw new Error("You cannot order your own product.");
      }

      const currentQuantity = Number(product.quantity || 0);
      const price = Number(product.price || 0);

      if (
        !product.isActive ||
        currentQuantity <= 0 ||
        !Number.isFinite(price) ||
        price < 0
      ) {
        throw new Error(
          `${product.name || "A product"} is no longer available.`
        );
      }

      if (item.quantity > currentQuantity) {
        throw new Error(
          `Only ${currentQuantity} ${product.unit || ""} available for ${product.name || "this product"}.`
        );
      }

      products.push(product);
    }

    for (let i = 0; i < normalizedItems.length; i++) {
      const item = normalizedItems[i];
      const product = products[i];

      if (!product) {
        continue;
      }

      const newQuantity =
        Number(product.quantity || 0) - item.quantity;

      const orderRef = orderRefs[i];

      transaction.update(productRefs[i], {
        quantity: newQuantity,
        isActive: newQuantity > 0,
      });

      transaction.set(orderRef, {
        id: item.orderId,
        buyerId: request.auth.uid,
        sellerId: product.sellerId,
        productId: item.productId,
        productName: product.name,
        quantity: item.quantity,
        totalPrice: Number(product.price) * item.quantity,
        status: "placed",
        deliveryAddress: deliveryAddress.trim(),
        createdAt: FieldValue.serverTimestamp(),
      });

      await createNotification(
        transaction,
        request.auth.uid,
        "Order placed",
        `${product.name} order placed successfully.`,
      );

      await createNotification(
        transaction,
        product.sellerId,
        "New order",
        `You received a new order for ${product.name}.`,
      );
    }
  });

  return {
    success: true,
    itemCount: normalizedItems.length,
  };
});
exports.updateOrderStatus = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in.");
  }

  const {orderId, nextStatus} = request.data || {};

  if (
    typeof orderId !== "string" ||
    typeof nextStatus !== "string" ||
    !orderId.trim()
  ) {
    throw new HttpsError("invalid-argument", "Invalid status update.");
  }

  const orderRef = db.collection("orders").doc(orderId);

  await db.runTransaction(async (transaction) => {
    const orderSnap = await transaction.get(orderRef);

    if (!orderSnap.exists) {
      throw new HttpsError("not-found", "Order not found.");
    }

    const order = orderSnap.data();

    if (order.sellerId !== request.auth.uid) {
      throw new HttpsError("permission-denied", "You cannot update this order.");
    }

    const currentIndex = STATUS_FLOW.indexOf(order.status);
    const nextIndex = STATUS_FLOW.indexOf(nextStatus);

    if (
      currentIndex < 0 ||
      nextIndex !== currentIndex + 1
    ) {
      throw new HttpsError("failed-precondition", "Invalid order status transition.");
    }

    transaction.update(orderRef, {
      status: nextStatus,
    });

    const readableStatus = nextStatus.replace(/_/g, " ");

    await createNotification(
      transaction,
      order.buyerId,
      "Order update",
      `${order.productName} is now ${readableStatus}.`,
    );
  });

  return {
    success: true,
    orderId,
    status: nextStatus,
  };
});


/*
 * Trusted price-history + price-alert pipeline.
 *
 * Product writes happen through Firestore.
 * This trigger records price history only when:
 * - a product is created, or
 * - its price changes.
 *
 * It then checks active alerts for the product category.
 */
exports.trackProductPrice = onDocumentWritten(
  "products/{productId}",
  async (event) => {
    const before = event.data.before;
    const after = event.data.after;

    if (!after.exists) {
      return;
    }

    const product = after.data();

    const beforeProduct = before.exists
      ? before.data()
      : null;

    const price = Number(product.price);
    const category = String(product.category || "").trim();

    if (
      !category ||
      !Number.isFinite(price) ||
      price < 0
    ) {
      return;
    }

    const priceChanged =
      !beforeProduct ||
      Number(beforeProduct.price) !== price ||
      String(beforeProduct.category || "").trim() !== category;

    if (!priceChanged) {
      return;
    }

    const categoryRef = db
      .collection("price_history")
      .doc(category.toLowerCase());

    const entryRef = categoryRef
      .collection("entries")
      .doc();

    await entryRef.set({
      id: entryRef.id,
      category,
      avgPrice: price,
      date: FieldValue.serverTimestamp(),
      productId: event.params.productId,
    });

    logger.info("Price history recorded", {
      productId: event.params.productId,
      category,
      price,
    });

    const alertsSnap = await db
      .collection("price_alerts")
      .where("category", "==", category)
      .where("isActive", "==", true)
      .where("notificationSent", "==", false)
      .get();

    if (alertsSnap.empty) {
      return;
    }

    const batch = db.batch();

    for (const alertDoc of alertsSnap.docs) {
      const alert = alertDoc.data();
      const targetPrice = Number(alert.targetPrice);

      if (
        !Number.isFinite(targetPrice) ||
        price > targetPrice
      ) {
        continue;
      }

      const notificationRef = db
        .collection("notifications")
        .doc();

      batch.set(notificationRef, {
        id: notificationRef.id,
        userId: alert.userId,
        title: "Price alert",
        body:
          `${category} is now Ã¢â€šÂ¹${price.toFixed(2)}, ` +
          `reaching your target price.`,
        isRead: false,
        createdAt: FieldValue.serverTimestamp(),
      });

      batch.update(alertDoc.ref, {
        notificationSent: true,
        isActive: false,
      });
    }

    await batch.commit();
  },
);
