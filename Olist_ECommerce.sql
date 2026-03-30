SELECT TOP 5 *
FROM olist_orders_dataset;

/*=========================================================================
   BÀI TOÁN 1: PHƯƠNG THỨC THANH TOÁN (PAYMENTS ANALYSIS)
   Mục tiêu: Khách hàng chuộng trả tiền bằng hình thức nào nhất và Dòng tiền chủ yếu đến từ đâu?
========================================================================= */
SELECT		payment_type AS [Phương Thức Thanh Toán],
			COUNT(order_id) AS [Số Lượng Giao Dịch],
			SUM(CAST(payment_value AS FLOAT)) AS [Tổng Doanh Thu]
FROM		olist_order_payments_dataset
GROUP BY	payment_type
ORDER BY	[Tổng Doanh Thu] DESC;

/*=========================================================================
   BÀI TOÁN 2: PHÂN TÍCH ĐỊA LÝ (GEOGRAPHIC ANALYSIS)
   Mục tiêu: Tìm ra top 10 Bang có số lượng đơn hàng lớn nhất để chạy Ads.
========================================================================= */
SELECT		TOP 10 c.customer_state AS [Bang],
			COUNT(o.order_id) AS [Số Lượng Đơn Hàng]
FROM		olist_orders_dataset o
JOIN		olist_customers_dataset c ON o.customer_id = c.customer_id
GROUP BY	c.customer_state
ORDER BY	[Số Lượng Đơn Hàng] DESC;

/* =========================================================================
   BÀI TOÁN 3: ẢNH HƯỞNG CỦA VẬN CHUYỂN ĐẾN SỰ HÀI LÒNG KHÁCH HÀNG
   Mục tiêu: Đánh giá xem việc giao hàng trễ làm giảm bao nhiêu sao đánh giá?
========================================================================= */
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

/* =========================================================================
   BÀI TOÁN 4: PHÂN TÍCH DOANH THU THEO DANH MÚC SẢN PHẨM (CATEGORY ANALYSIS)
   Mục tiêu: Tìm ra Top 10 danh mục sản phẩm mang lại doanh thu cao nhất.
========================================================================= */
SELECT		TOP 10 t.product_category_name_english AS [Danh Mục Sản Phẩm],
			COUNT(i.order_item_id) AS [Số Lượng Đã Bán],
			ROUND(SUM(CAST(i.price AS FLOAT)), 2) AS [Tổng Doanh Thu]
FROM		olist_order_items_dataset i
JOIN		olist_products_dataset p ON i.product_id = p.product_id
JOIN		product_category_name_translation t ON p.product_category_name = t.product_category_name
GROUP BY	t.product_category_name_english
ORDER BY	[Tổng Doanh Thu] DESC;

/* =========================================================================
   BÀI TOÁN 5: XU HƯỚNG DOANH THU THEO THÁNG (MONTHLY SALES TREND)
   Mục tiêu: Theo dõi tăng trưởng doanh thu qua các tháng và năm.
========================================================================= */
SELECT		YEAR(o.order_purchase_timestamp) AS [Năm],
			MONTH(o.order_purchase_timestamp) AS [Tháng],
			COUNT(o.order_id) AS [Số Lượng Đơn Hàng],
			ROUND(SUM(CAST(p.payment_value AS FLOAT)), 2) AS [Doanh Thu]
FROM		olist_orders_dataset o
JOIN		olist_order_payments_dataset p ON o.order_id = p.order_id
WHERE		o.order_status <> 'canceled'
GROUP BY	YEAR(o.order_purchase_timestamp), MONTH(o.order_purchase_timestamp)
ORDER BY	[Năm], [Tháng];