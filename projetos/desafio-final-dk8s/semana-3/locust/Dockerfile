FROM python:3.11-slim AS builder
WORKDIR /app
RUN pip install --no-cache-dir locust httpx --target=/packages

FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /packages /packages
COPY locustfile.py /locustfile.py
ENV PYTHONPATH=/packages
ENV PATH=/packages/bin:$PATH
USER nobody
EXPOSE 8089
ENTRYPOINT ["locust"]
CMD ["-f", "/locustfile.py", "--web-port=8089"]
