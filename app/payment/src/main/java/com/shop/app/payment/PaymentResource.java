package com.shop.app.payment;

import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.logging.Logger;

@Path("/api")
public class PaymentResource {

    private static final Logger LOGGER = Logger.getLogger(PaymentResource.class.getName());
    private static final Map<String, Map<String, Object>> transactions = new ConcurrentHashMap<>();

    @POST
    @Path("/process")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response processPayment(Map<String, Object> request) {
        String orderId = (String) request.get("orderId");
        double amount = ((Number) request.getOrDefault("amount", 0.0)).doubleValue();
        String currency = (String) request.getOrDefault("currency", "USD");

        LOGGER.info("PaymentService: Processing payment for order " + orderId + ": " + amount + " " + currency);

        simulateWork(100, 300);

        // Simulate payment gateway call
        boolean success = simulatePaymentGateway(amount);

        String transactionId = UUID.randomUUID().toString();
        String status = success ? "success" : "failed";

        Map<String, Object> transaction = new HashMap<>();
        transaction.put("transactionId", transactionId);
        transaction.put("orderId", orderId);
        transaction.put("amount", amount);
        transaction.put("currency", currency);
        transaction.put("status", status);
        transaction.put("timestamp", System.currentTimeMillis());

        transactions.put(transactionId, transaction);

        if (success) {
            LOGGER.info("PaymentService: Payment successful for order " + orderId);
        } else {
            LOGGER.warning("PaymentService: Payment failed for order " + orderId);
        }

        return Response.ok(transaction).build();
    }

    @GET
    @Path("/transaction/{transactionId}")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getTransaction(@PathParam("transactionId") String transactionId) {
        LOGGER.info("PaymentService: Fetching transaction " + transactionId);

        simulateWork(30, 70);

        Map<String, Object> transaction = transactions.get(transactionId);
        if (transaction == null) {
            return Response.status(404)
                    .entity(Map.of("error", "Transaction not found"))
                    .build();
        }

        return Response.ok(transaction).build();
    }

    @GET
    @Path("/health")
    @Produces(MediaType.APPLICATION_JSON)
    public Response health() {
        return Response.ok(Map.of(
                "service", "payment-service",
                "status", "healthy",
                "total_transactions", transactions.size()
        )).build();
    }

    private boolean simulatePaymentGateway(double amount) {
        // Simulate 95% success rate
        // Fail more often for large amounts
        if (amount > 1000) {
            return Math.random() > 0.1;
        }
        return Math.random() > 0.05;
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
