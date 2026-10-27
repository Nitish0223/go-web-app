# Go Web Application

This is a simple website written in Golang. It uses the `net/http` package to serve HTTP requests.

## Running the server

To run the server, execute the following command:

```bash
go run main.go
```

The server will start on port 8080. You can access it by navigating to `http://localhost:8080/courses` in your web browser.

Available pages: `/home`, `/courses`, `/about`, `/contact`. There is no page at `/`, so it returns 404.

## Running with Docker

```bash
docker build -t nitish022002/go-web-app:v1 .
docker run -p 8080:8080 nitish022002/go-web-app:v1
```

## Deploying to Kubernetes with Helm

The chart in `helm/go-web-app-chart` deploys a Deployment, Service, HorizontalPodAutoscaler and an HTTPS Ingress for `app.myexample.sbs`.

Prerequisites in the cluster:

- [ingress-nginx](https://kubernetes.github.io/ingress-nginx/) (ingress class `nginx`)
- [cert-manager](https://cert-manager.io/) with CRDs installed
- metrics-server (for the HPA)
- A DNS record for `app.myexample.sbs` pointing at the ingress-nginx load balancer

Install or upgrade:

```bash
helm upgrade --install go-web-app helm/go-web-app-chart
```

The chart creates a `letsencrypt-prod` ClusterIssuer, and cert-manager stores the issued certificate in the `go-web-app-tls` secret. Settings such as the image, host, replicas and autoscaling live in `helm/go-web-app-chart/values.yaml`.

Once deployed, the app is available at `https://app.myexample.sbs/home`.

## Looks like this

![Website](static/images/golang-website.png)


