package com.shop.app.gateway;

import jakarta.ws.rs.*;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.ClientBuilder;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.logging.Logger;

@Path("/api")
public class GatewayResource {

    private static final Logger LOGGER = Logger.getLogger(GatewayResource.class.getName());
    private static final String ORDER_SERVICE = "http://localhost:8081/order/api";

    @GET
    @Path("/health")
    @Produces(MediaType.APPLICATION_JSON)
    public Response health() {
        Map<String, Object> response = new HashMap<>();
        response.put("service", "api-gateway");
        response.put("status", "healthy");
        response.put("timestamp", System.currentTimeMillis());
        return Response.ok(response).build();
    }

    @POST
    @Path("/orders")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response createOrder(Map<String, Object> orderRequest) {
        String orderId = UUID.randomUUID().toString();
        LOGGER.info("Gateway: Received order request: " + orderId);

        // Simulate some gateway processing
        simulateWork(50, 100);

        // Forward to order service
        try (Client client = ClientBuilder.newClient()) {
            Map<String, Object> enrichedRequest = new HashMap<>(orderRequest);
            enrichedRequest.put("orderId", orderId);
            enrichedRequest.put("gateway_timestamp", System.currentTimeMillis());

            Response orderResponse = client.target(ORDER_SERVICE + "/orders")
                    .request(MediaType.APPLICATION_JSON)
                    .post(Entity.json(enrichedRequest));

            Map<String, Object> result = orderResponse.readEntity(Map.class);
            return Response.status(orderResponse.getStatus()).entity(result).build();
        } catch (Exception e) {
            LOGGER.severe("Gateway: Error calling order service: " + e.getMessage());
            Map<String, String> error = new HashMap<>();
            error.put("error", "Service unavailable");
            error.put("service", "order-service");
            return Response.status(503).entity(error).build();
        }
    }

    @GET
    @Path("/orders/{orderId}")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getOrder(@PathParam("orderId") String orderId) {
        LOGGER.info("Gateway: Fetching order: " + orderId);

        simulateWork(20, 50);

        try (Client client = ClientBuilder.newClient()) {
            Response orderResponse = client.target(ORDER_SERVICE + "/orders/" + orderId)
                    .request(MediaType.APPLICATION_JSON)
                    .get();

            if (orderResponse.getStatus() == 200) {
                Map<String, Object> result = orderResponse.readEntity(Map.class);
                return Response.ok(result).build();
            } else {
                return Response.status(orderResponse.getStatus())
                        .entity(orderResponse.readEntity(String.class))
                        .build();
            }
        } catch (Exception e) {
            LOGGER.severe("Gateway: Error fetching order: " + e.getMessage());
            return Response.status(503).entity("{\"error\":\"Service unavailable\"}").build();
        }
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
