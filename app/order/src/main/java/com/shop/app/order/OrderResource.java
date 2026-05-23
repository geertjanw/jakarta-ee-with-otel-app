package com.shop.app.order;

import jakarta.ws.rs.*;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.ClientBuilder;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.logging.Logger;

@Path("/api/orders")
public class OrderResource {

    private static final Logger LOGGER = Logger.getLogger(OrderResource.class.getName());
    private static final String INVENTORY_SERVICE = "http://localhost:8082/inventory/api";
    private static final String PAYMENT_SERVICE = "http://localhost:8083/payment/api";
    private static final String NOTIFICATION_SERVICE = "http://localhost:8084/notification/api";

    private static final Map<String, Map<String, Object>> orders = new ConcurrentHashMap<>();

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response createOrder(Map<String, Object> orderData) {
        String orderId = (String) orderData.get("orderId");
        LOGGER.info("OrderService: Processing order: " + orderId);

        simulateWork(100, 200);

        // Check inventory
        boolean inventoryAvailable = checkInventory(orderData);
        if (!inventoryAvailable) {
            return Response.status(400)
                    .entity(Map.of("error", "Insufficient inventory", "orderId", orderId))
                    .build();
        }

        // Process payment
        boolean paymentSuccess = processPayment(orderData);
        if (!paymentSuccess) {
            return Response.status(402)
                    .entity(Map.of("error", "Payment failed", "orderId", orderId))
                    .build();
        }

        // Create order
        Map<String, Object> order = new HashMap<>(orderData);
        order.put("status", "confirmed");
        order.put("created_at", System.currentTimeMillis());
        orders.put(orderId, order);

        // Send notification (async - fire and forget)
        sendNotification(orderId, "Order confirmed");

        LOGGER.info("OrderService: Order created successfully: " + orderId);
        return Response.status(201).entity(order).build();
    }

    @GET
    @Path("/{orderId}")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getOrder(@PathParam("orderId") String orderId) {
        LOGGER.info("OrderService: Fetching order: " + orderId);

        simulateWork(30, 80);

        Map<String, Object> order = orders.get(orderId);
        if (order == null) {
            return Response.status(404)
                    .entity(Map.of("error", "Order not found", "orderId", orderId))
                    .build();
        }

        return Response.ok(order).build();
    }

    private boolean checkInventory(Map<String, Object> orderData) {
        try (Client client = ClientBuilder.newClient()) {
            Map<String, Object> request = Map.of(
                    "product", orderData.getOrDefault("product", "unknown"),
                    "quantity", orderData.getOrDefault("quantity", 1)
            );

            Response response = client.target(INVENTORY_SERVICE + "/check")
                    .request(MediaType.APPLICATION_JSON)
                    .post(Entity.json(request));

            Map<String, Object> result = response.readEntity(Map.class);
            return (Boolean) result.getOrDefault("available", false);
        } catch (Exception e) {
            LOGGER.severe("OrderService: Error checking inventory: " + e.getMessage());
            return false;
        }
    }

    private boolean processPayment(Map<String, Object> orderData) {
        try (Client client = ClientBuilder.newClient()) {
            Map<String, Object> request = Map.of(
                    "orderId", orderData.get("orderId"),
                    "amount", orderData.getOrDefault("amount", 100.0),
                    "currency", "USD"
            );

            Response response = client.target(PAYMENT_SERVICE + "/process")
                    .request(MediaType.APPLICATION_JSON)
                    .post(Entity.json(request));

            Map<String, Object> result = response.readEntity(Map.class);
            return "success".equals(result.get("status"));
        } catch (Exception e) {
            LOGGER.severe("OrderService: Error processing payment: " + e.getMessage());
            return false;
        }
    }

    private void sendNotification(String orderId, String message) {
        new Thread(() -> {
            try (Client client = ClientBuilder.newClient()) {
                Map<String, Object> request = Map.of(
                        "orderId", orderId,
                        "message", message,
                        "channel", "email"
                );

                client.target(NOTIFICATION_SERVICE + "/send")
                        .request(MediaType.APPLICATION_JSON)
                        .post(Entity.json(request));
            } catch (Exception e) {
                LOGGER.warning("OrderService: Failed to send notification: " + e.getMessage());
            }
        }).start();
    }

    private void simulateWork(int minMs, int maxMs) {
        try {
            int delay = minMs + (int)(Math.random() * (maxMs - minMs));
            Thread.sleep(delay);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
