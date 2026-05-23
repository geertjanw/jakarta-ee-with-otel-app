package com.shop.app.notification;

import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.logging.Logger;

@Path("/api")
public class NotificationResource {

    private static final Logger LOGGER = Logger.getLogger(NotificationResource.class.getName());
    private static final Map<String, List<Map<String, Object>>> notifications = new ConcurrentHashMap<>();

    @POST
    @Path("/send")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response sendNotification(Map<String, Object> request) {
        String orderId = (String) request.get("orderId");
        String message = (String) request.get("message");
        String channel = (String) request.getOrDefault("channel", "email");

        LOGGER.info("NotificationService: Sending " + channel + " notification for order " + orderId);

        simulateWork(80, 200);

        String notificationId = UUID.randomUUID().toString();

        Map<String, Object> notification = new HashMap<>();
        notification.put("notificationId", notificationId);
        notification.put("orderId", orderId);
        notification.put("message", message);
        notification.put("channel", channel);
        notification.put("status", "sent");
        notification.put("timestamp", System.currentTimeMillis());

        notifications.computeIfAbsent(orderId, k -> new ArrayList<>()).add(notification);

        LOGGER.info("NotificationService: Notification sent: " + notificationId);

        return Response.ok(notification).build();
    }

    @GET
    @Path("/notifications/{orderId}")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getNotifications(@PathParam("orderId") String orderId) {
        LOGGER.info("NotificationService: Fetching notifications for order " + orderId);

        simulateWork(20, 50);

        List<Map<String, Object>> orderNotifications = notifications.getOrDefault(orderId, new ArrayList<>());

        Map<String, Object> response = Map.of(
                "orderId", orderId,
                "count", orderNotifications.size(),
                "notifications", orderNotifications
        );

        return Response.ok(response).build();
    }

    @GET
    @Path("/health")
    @Produces(MediaType.APPLICATION_JSON)
    public Response health() {
        int totalNotifications = notifications.values().stream()
                .mapToInt(List::size)
                .sum();

        return Response.ok(Map.of(
                "service", "notification-service",
                "status", "healthy",
                "total_notifications", totalNotifications
        )).build();
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
