Create database RFM;
use RFM;

-- recency
-- frequency
-- monetory
create or replace view rfm_view as 
with RFM_values as (
select customername,
	datediff((select max(str_to_date(orderdate,'%d/%m/%y')) from sales),
	max(str_to_date(orderdate,'%d/%m/%y'))) as recency_values,
    count(distinct ordernumber) as frequency_values,
    round(sum(sales),2) as monetary_values
    from sales
group by customername),
rfm_score as(
select rv.*,
	ntile(5) over(order by recency_values desc) as r_score,
    ntile(5) over (order by frequency_values) as f_score,
    ntile(5) over(order by monetary_values) as m_score
from
RFM_values rv),
rfm_combination as (
select rs.*,
	(r_score+f_score+m_score) as total_rfm_score,
    concat(r_score,f_score,m_score) as RFM_SCORE_COMBINATION
	
from rfm_score rs)
select rc.*,
	CASE
		WHEN RFM_SCORE_COMBINATION IN (455, 542, 544, 552, 553, 452, 545, 554, 555) THEN 'Champions'
        WHEN RFM_SCORE_COMBINATION IN (344, 345, 353, 354, 355, 443, 451, 342, 351, 352, 441, 442, 444, 445, 453, 454, 541, 543, 515, 551) THEN 'Loyal Customers'
        WHEN RFM_SCORE_COMBINATION IN (513, 413, 511, 411, 512, 341, 412, 343, 514) THEN 'Potential Loyalists'
        WHEN RFM_SCORE_COMBINATION IN (414, 415, 214, 211, 212, 213, 241, 251, 312, 314, 311, 313, 315, 243, 245, 252, 253, 255, 242, 244, 254) THEN 'Promising Customers'
        WHEN RFM_SCORE_COMBINATION IN (141, 142,143,144,151,152,155,145,153,154,215) THEN 'Needs Attention'
        WHEN RFM_SCORE_COMBINATION IN (113, 111, 112, 114, 115) THEN 'About to Sleep'
        ELSE 'Other' END
        AS RFM_SEGMENTS
from rfm_combination rc;
    
select customername,
	rfm_segments,
    avg(recency_values) over(partition by rfm_segments) as avg_recency,
    avg(frequency_values) over(partition by rfm_segments) as avg_frequecy,
    avg(monetary_values) over(partition by rfm_segments) as avg_monetarty,
    count(*) over(partition by rfm_segments) as segment_count
 from rfm_view;
