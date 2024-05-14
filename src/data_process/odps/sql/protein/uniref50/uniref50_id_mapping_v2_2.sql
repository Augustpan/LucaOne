--odps sql
--********************************************************************--
--author:sanyuan_xhs_test
--create time:2023-11-02 14:11:03
--********************************************************************--

-- 每个蛋白的label进行组装
-- label文件需要先从sql文件prot_label_list中导入到本地，然后以资源的信息上传（这样做是为了与后面算法label文件保存一致）
-- 需要获取
-- prot_site_span_level_label_v2.txt
-- prot_homo_span_level_label_v2.txt
-- prot_domain_span_level_label_v2.txt
-- prot_taxonomy_seq_level_label_v2.txt
-- prot_keyword_seq_level_label_v2.txt
-- 并上传资源

SET odps.sql.python.version=cp37;


DROP TABLE IF EXISTS tmp_lucaone_v2_uniref50_all_detail_step1_v2;

CREATE TABLE IF NOT EXISTS tmp_lucaone_v2_uniref50_all_detail_step1_v2 AS
SELECT  prot_seq_accession AS seq_id
     ,seq
     ,sprot_label_process_v2(
        prot_seq_accession
    ,taxid
    ,order_bio
    ,keywords
    ,prot_feature_name
    ,prot_feature_type
    ,start_p
    ,end_p
    ) AS labels
FROM    tmp_lucaone_v2_uniref50_label_detail_all_v2
GROUP BY prot_seq_accession, seq
;
-- 对不存在的label信息进行占位符占位

SET odps.sql.python.version=cp37;

DROP TABLE IF EXISTS tmp_lucaone_v2_uniref50_all_detail_step2_v2 ;

CREATE TABLE IF NOT EXISTS tmp_lucaone_v2_uniref50_all_detail_step2_v2 AS
SELECT  seq_id
     ,seq
     ,prot_label_fill_v2(seq_id, labels) AS labels
FROM    tmp_lucaone_v2_uniref50_all_detail_step1_v2
;
-- 验证span不能超过序列长度

SET odps.sql.python.version=cp37;


DROP TABLE IF EXISTS tmp_lucaone_v2_uniref50_all_detail_v2 ;

CREATE TABLE tmp_lucaone_v2_uniref50_all_detail_v2 AS
SELECT  seq_id
     ,seq
     ,labels
FROM    (
            SELECT  seq_id
                 ,seq
                 ,labels
                 ,span_verify_v2(seq_id, seq, labels) AS flag
            FROM    tmp_lucaone_v2_uniref50_all_detail_step2_v2
        ) t1
WHERE   flag IS NULL
;

