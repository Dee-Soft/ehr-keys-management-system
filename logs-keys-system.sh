#!/bin/bash
echo "OpenBao logs:"
docker logs openbao --tail 50
echo ""
echo "PostgreSQL logs:"
docker logs postgres-keys --tail 20