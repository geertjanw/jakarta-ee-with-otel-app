package com.shop.app.inventory;

import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.logging.Logger;

@Path("/api")
public class InventoryResource {

    private static final Logger LOGGER = Logger.getLogger(InventoryResource.class.getName());
    private static final Map<String, Integer> inventory = new ConcurrentHashMap<>();

    static {
        // Initialize inventory
        inventory.put("laptop", 50);
        inventory.put("phone", 100);
        inventory.put("tablet", 30);
        inventory.put("monitor", 25);
    }

    @POST
    @Path("/check")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response checkInventory(Map<String, Object> request) {
        String product = (String) request.get("product");
        int quantity = ((Number) request.getOrDefault("quantity", 1)).intValue();

        LOGGER.info("InventoryService: Checking inventory for " + product + " (qty: " + quantity + ")");

        simulateWork(50, 150);

        int available = inventory.getOrDefault(product, 0);
        boolean isAvailable = available >= quantity;

        Map<String, Object> response = new HashMap<>();
        response.put("product", product);
        response.put("requested", quantity);
        response.put("available", isAvailable);
        response.put("stock", available);
        response.put("timestamp", System.currentTimeMillis());

        if (isAvailable) {
            // Reserve inventory
            inventory.put(product, available - quantity);
            LOGGER.info("InventoryService: Reserved " + quantity + " " + product);
        } else {
            LOGGER.warning("InventoryService: Insufficient stock for " + product);
        }

        return Response.ok(response).build();
    }

    @GET
    @Path("/stock/{product}")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getStock(@PathParam("product") String product) {
        LOGGER.info("InventoryService: Querying stock for " + product);

        simulateWork(20, 50);

        int stock = inventory.getOrDefault(product, 0);

        Map<String, Object> response = Map.of(
                "product", product,
                "stock", stock,
                "timestamp", System.currentTimeMillis()
        );

        return Response.ok(response).build();
    }

    @GET
    @Path("/health")
    @Produces(MediaType.APPLICATION_JSON)
    public Response health() {
        return Response.ok(Map.of(
                "service", "inventory-service",
                "status", "healthy",
                "total_products", inventory.size()
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
