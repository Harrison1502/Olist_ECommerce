# Brazilian E-Commerce Business Analysis (Olist)

## Tổng Quan Dự Án
Dự án phân tích dữ liệu thực tế từ Olist - sàn thương mại điện tử lớn nhất Brazil, với bộ dữ liệu bao gồm hơn 100,000 đơn hàng được phân bổ trong 9 bảng cơ sở dữ liệu quan hệ (Relational Database). 
Mục tiêu của dự án là trích xuất dữ liệu, kết nối các bảng và đưa ra những góc nhìn sâu sắc về hành vi khách hàng, hiệu suất logistics và xu hướng doanh thu để hỗ trợ ra quyết định kinh doanh (Data-driven decision making).

- **Công cụ sử dụng:** Microsoft SQL Server (SSMS)
- **Dataset:** Brazilian E-Commerce Public Dataset by Olist (Kaggle)

## Business Insights & SQL Queries (Phân tích & Truy vấn)
### 1. Phân tích Hành vi Thanh toán (Payment Behavior)
**Mục tiêu:** Xác định phương thức thanh toán mang lại dòng tiền lớn nhất cho hệ thống.

```sql
SELECT		payment_type AS [Phương Thức Thanh Toán],
            COUNT(order_id) AS [Số Lượng Giao Dịch],
            SUM(CAST(payment_value AS FLOAT)) AS [Tổng Doanh Thu]
FROM		olist_order_payments_dataset
GROUP BY	payment_type
ORDER BY	[Tổng Doanh Thu] DESC;
```
<img width="404" height="137" alt="image" src="https://github.com/user-attachments/assets/995f7fb5-f69c-4ce7-954d-e6144579bd31" />

**Insights:**
- Giao dịch qua Thẻ tín dụng (Credit Card) chiếm tỷ trọng doanh thu cao nhất (~12.5 triệu BRL).
- Phương thức trả tiền mặt/phiếu in (Boleto) vẫn giữ vị trí thứ hai, cho thấy cần duy trì hệ thống thanh toán truyền thống này để đáp ứng đặc thù văn hóa mua sắm tại Brazil.

### 2. Phân tích Địa lý & Thị trường (Geographic Analysis)
**Mục tiêu:** Định vị các bang có sức mua lớn nhất để phân bổ ngân sách Marketing.

```sql
SELECT		TOP 10 c.customer_state AS [Bang],
			COUNT(o.order_id) AS [Số Lượng Đơn Hàng]
FROM		olist_orders_dataset o
JOIN		olist_customers_dataset c ON o.customer_id = c.customer_id
GROUP BY	c.customer_state
ORDER BY	[Số Lượng Đơn Hàng] DESC;
```
<img width="198" height="243" alt="image" src="https://github.com/user-attachments/assets/3b38c2c5-571e-41c7-a457-db218d00f928" />

**Insights:**
- Bang São Paulo (SP) là trung tâm kinh tế trọng điểm, mang lại số lượng đơn hàng áp đảo (hơn 41,000 đơn).
- Đề xuất dồn trọng tâm ngân sách quảng cáo ngoài trời (Billboard) và xây dựng Tổng kho (Fulfillment Center) tại khu vực này.

### 3. Tác động của Logistics đến Trải nghiệm Khách hàng
Mục tiêu: Đánh giá mức độ sụt giảm hài lòng (Review Score) khi giao hàng trễ hẹn.

```sql
SELECT		CASE 
			WHEN CAST(o.order_delivered_customer_date AS DATETIME) > CAST(o.order_estimated_delivery_date AS DATETIME) THEN 'Late'
			ELSE 'On Time'
			END AS [Tình Trạng Giao Hàng],
			COUNT(o.order_id) AS [Số Lượng Đơn Hàng],
			ROUND(AVG(CAST(r.review_score AS FLOAT)), 2) AS [Điểm Sao Trung Bình]
FROM		olist_orders_dataset o
JOIN		olist_order_reviews_dataset r ON o.order_id = r.order_id
WHERE		o.order_status = 'delivered'
			AND o.order_delivered_customer_date IS NOT NULL 
GROUP BY	CASE 
			WHEN CAST(o.order_delivered_customer_date AS DATETIME) > CAST(o.order_estimated_delivery_date AS DATETIME) THEN 'Late'
			ELSE 'On Time'
			END;
```
<img width="393" height="91" alt="image" src="https://github.com/user-attachments/assets/062c15a8-160c-40a2-a8cb-1485493bd46f" />

**Insights:**
- Giao hàng đúng hạn giúp duy trì mức đánh giá cao (4.29 sao).
- Tuy nhiên, khi giao trễ, điểm số lập tức sụt giảm nghiêm trọng chỉ còn 2.28 sao.
- Cần thiết lập SLA khắt khe hơn với các đối tác vận chuyển để bảo vệ uy tín thương hiệu.

### 4. Phân tích Hiệu suất Ngành hàng (Category Performance)
Mục tiêu: Xác định Top 10 danh mục sản phẩm có doanh thu cao nhất.

```sql
SELECT		TOP 10 t.product_category_name_english AS [Danh Mục Sản Phẩm],
			COUNT(i.order_item_id) AS [Số Lượng Đã Bán],
			ROUND(SUM(CAST(i.price AS FLOAT)), 2) AS [Tổng Doanh Thu]
FROM		olist_order_items_dataset i
JOIN		olist_products_dataset p ON i.product_id = p.product_id
JOIN		product_category_name_translation t ON p.product_category_name = t.product_category_name
GROUP BY	t.product_category_name_english
ORDER BY	[Tổng Doanh Thu] DESC;
```
<img width="363" height="242" alt="image" src="https://github.com/user-attachments/assets/c6f90bab-9f62-4a67-842a-fe9c5c904ac1" />

**Insights:**
- Các ngành hàng như Health & Beauty, Watches & Gifts mang lại doanh thu đột phá.
- Cần đảm bảo lượng hàng tồn kho an toàn cho các nhóm này và thiết kế các chiến dịch bán chéo (Cross-selling).

### 5. Xu hướng Doanh thu theo Thời gian (Monthly Sales Trend)
Mục tiêu: Theo dõi tăng trưởng doanh thu để tìm ra mùa cao điểm.

```sql
SELECT		YEAR(o.order_purchase_timestamp) AS [Năm],
			MONTH(o.order_purchase_timestamp) AS [Tháng],
			COUNT(o.order_id) AS [Số Lượng Đơn Hàng],
			ROUND(SUM(CAST(p.payment_value AS FLOAT)), 2) AS [Doanh Thu]
FROM		olist_orders_dataset o
JOIN		olist_order_payments_dataset p ON o.order_id = p.order_id
WHERE		o.order_status <> 'canceled'
GROUP BY	YEAR(o.order_purchase_timestamp), MONTH(o.order_purchase_timestamp)
ORDER BY	[Năm], [Tháng];
```
<img width="312" height="499" alt="image" src="https://github.com/user-attachments/assets/cd519004-9292-4d23-8cdd-d103cad1adc9" />

**Insights:**
- Ghi nhận sự bùng nổ doanh thu vào Tháng 11/2017 (đỉnh điểm Black Friday).
- Hệ thống cần chuẩn bị cơ sở hạ tầng server và kho bãi từ cuối quý 3 hàng năm để đón đầu làn sóng mua sắm cuối năm.

## Conclusion (Kết luận)
Dự án đã sử dụng linh hoạt các kỹ thuật truy vấn SQL nâng cao để biến dữ liệu thô (Raw Data) thành những đề xuất chiến lược thực tế, tối ưu hóa từ khâu Marketing, Logistics đến Quản trị danh mục sản phẩm.

Contact me: https://www.linkedin.com/in/harrison1502/
