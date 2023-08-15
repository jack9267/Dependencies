disable_rtti()

include(CheckTypeSize)

set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/src" ${CMAKE_MODULE_PATH})
include(cmake_export_symbol)

file(READ ${CMAKE_CURRENT_SOURCE_DIR}/src/ssl/VERSION SSL_VERSION)
string(STRIP ${SSL_VERSION} SSL_VERSION)
string(REPLACE ":" "." SSL_VERSION ${SSL_VERSION})
string(REGEX REPLACE "\\..*" "" SSL_MAJOR_VERSION ${SSL_VERSION})

file(READ ${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/VERSION CRYPTO_VERSION)
string(STRIP ${CRYPTO_VERSION} CRYPTO_VERSION)
string(REPLACE ":" "." CRYPTO_VERSION ${CRYPTO_VERSION})
string(REGEX REPLACE "\\..*" "" CRYPTO_MAJOR_VERSION ${CRYPTO_VERSION})

file(READ ${CMAKE_CURRENT_SOURCE_DIR}/src/tls/VERSION TLS_VERSION)
string(STRIP ${TLS_VERSION} TLS_VERSION)
string(REPLACE ":" "." TLS_VERSION ${TLS_VERSION})
string(REGEX REPLACE "\\..*" "" TLS_MAJOR_VERSION ${TLS_VERSION})

add_definitions(-DLIBRESSL_INTERNAL)
add_definitions(-DOPENSSL_NO_HW_PADLOCK)
add_definitions(-D__BEGIN_HIDDEN_DECLS=)
add_definitions(-D__END_HIDDEN_DECLS=)

if(WIN32)
	add_definitions(-Drestrict)
	add_definitions(-D_CRT_SECURE_NO_WARNINGS)
	add_definitions(-D_CRT_DEPRECATED_NO_WARNINGS)
	add_definitions(-D_REENTRANT -D_POSIX_THREAD_SAFE_FUNCTIONS)
	add_definitions(-DWIN32_LEAN_AND_MEAN -D_WIN32_WINNT=0x0501)
	add_definitions(-DCPPFLAGS -DOPENSSL_NO_SPEED -DNO_SYSLOG -DNO_CRYPT)
endif()

add_definitions(-Dinline=__inline)

if(WIN32)
	add_definitions(-DHAVE_STRNLEN)
endif()

check_type_size(time_t SIZEOF_TIME_T)
if(SIZEOF_TIME_T STREQUAL "4")
	set(SMALL_TIME_T true)
	add_definitions(-DSMALL_TIME_T)
	message(WARNING " ** Warning, this system is unable to represent times past 2038\n"
	                " ** It will behave incorrectly when handling valid RFC5280 dates")
endif()
add_definitions(-DSIZEOF_TIME_T=${SIZEOF_TIME_T})

add_definitions(-DOPENSSL_NO_ASM)

set(CRYPTO_SOURCES
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/aes/aes_cbc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/aes/aes_core.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/camellia/camellia.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/camellia/cmll_cbc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rc4/rc4_enc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rc4/rc4_skey.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/whrlpool/wp_block.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/cpt_err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/cryptlib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/crypto_init.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/cversion.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ex_data.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/malloc-wrapper.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/mem_clr.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/mem_dbg.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/o_init.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/o_str.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/o_time.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/aes/aes_cfb.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/aes/aes_ctr.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/aes/aes_ecb.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/aes/aes_ige.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/aes/aes_misc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/aes/aes_ofb.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/aes/aes_wrap.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/a_bitstr.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/a_bool.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/a_bytes.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/a_d2i_fp.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/a_digest.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/a_dup.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/a_enum.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/a_i2d_fp.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/a_int.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/a_mbstr.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/a_object.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/a_octet.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/a_print.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/a_set.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/a_sign.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/a_strex.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/a_strnid.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/a_time.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/a_time_tm.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/a_type.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/a_utf8.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/a_verify.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/ameth_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/asn1_err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/asn1_gen.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/asn1_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/asn1_par.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/asn_mime.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/asn_moid.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/asn_pack.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/bio_asn1.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/bio_ndef.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/d2i_pr.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/d2i_pu.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/evp_asn1.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/f_enum.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/f_int.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/f_string.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/i2d_pr.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/i2d_pu.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/n_pkey.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/nsseq.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/p5_pbe.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/p5_pbev2.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/p8_pkey.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/t_bitst.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/t_crl.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/t_pkey.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/t_req.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/t_spki.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/t_x509.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/t_x509a.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/tasn_dec.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/tasn_enc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/tasn_fre.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/tasn_new.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/tasn_prn.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/tasn_typ.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/tasn_utl.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/x_algor.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/x_attrib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/x_bignum.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/x_crl.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/x_exten.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/x_info.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/x_long.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/x_name.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/x_nx509.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/x_pkey.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/x_pubkey.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/x_req.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/x_sig.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/x_spki.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/x_val.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/x_x509.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1/x_x509a.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bf/bf_cfb64.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bf/bf_ecb.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bf/bf_enc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bf/bf_ofb64.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bf/bf_skey.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bio/b_dump.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bio/b_print.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bio/b_sock.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bio/bf_buff.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bio/bf_nbio.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bio/bf_null.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bio/bio_cb.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bio/bio_err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bio/bio_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bio/bio_meth.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bio/bss_acpt.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bio/bss_bio.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bio/bss_conn.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bio/bss_dgram.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bio/bss_fd.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bio/bss_file.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bio/bss_mem.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bio/bss_null.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bio/bss_sock.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_add.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_asm.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_blind.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_const.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_ctx.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_depr.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_div.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_exp.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_exp2.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_gcd.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_gf2m.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_kron.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_mod.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_mont.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_mpi.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_mul.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_nist.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_prime.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_print.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_rand.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_recp.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_shift.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_sqr.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_sqrt.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_word.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn/bn_x931p.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/buffer/buf_err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/buffer/buf_str.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/buffer/buffer.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/camellia/cmll_cfb.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/camellia/cmll_ctr.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/camellia/cmll_ecb.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/camellia/cmll_misc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/camellia/cmll_ofb.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/cast/c_cfb64.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/cast/c_ecb.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/cast/c_enc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/cast/c_ofb64.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/cast/c_skey.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/chacha/chacha.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/cmac/cm_ameth.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/cmac/cm_pmeth.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/cmac/cmac.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/comp/c_rle.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/comp/c_zlib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/comp/comp_err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/comp/comp_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/conf/conf_api.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/conf/conf_def.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/conf/conf_err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/conf/conf_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/conf/conf_mall.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/conf/conf_mod.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/conf/conf_sap.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/curve25519/curve25519-generic.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/curve25519/curve25519.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/des/cbc_cksm.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/des/cbc_enc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/des/cfb64ede.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/des/cfb64enc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/des/cfb_enc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/des/des_enc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/des/ecb3_enc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/des/ecb_enc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/des/ede_cbcm_enc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/des/enc_read.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/des/enc_writ.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/des/fcrypt.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/des/fcrypt_b.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/des/ofb64ede.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/des/ofb64enc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/des/ofb_enc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/des/pcbc_enc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/des/qud_cksm.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/des/rand_key.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/des/set_key.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/des/str2key.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/des/xcbc_enc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dh/dh_ameth.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dh/dh_asn1.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dh/dh_check.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dh/dh_depr.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dh/dh_err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dh/dh_gen.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dh/dh_key.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dh/dh_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dh/dh_pmeth.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dh/dh_prn.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dsa/dsa_ameth.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dsa/dsa_asn1.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dsa/dsa_depr.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dsa/dsa_err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dsa/dsa_gen.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dsa/dsa_key.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dsa/dsa_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dsa/dsa_meth.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dsa/dsa_ossl.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dsa/dsa_pmeth.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dsa/dsa_prn.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dsa/dsa_sign.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dsa/dsa_vrf.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dso/dso_dlfcn.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dso/dso_err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dso/dso_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dso/dso_null.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dso/dso_openssl.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ec/ec2_mult.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ec/ec2_oct.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ec/ec2_smpl.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ec/ec_ameth.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ec/ec_asn1.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ec/ec_check.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ec/ec_curve.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ec/ec_cvt.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ec/ec_err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ec/ec_key.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ec/ec_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ec/ec_mult.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ec/ec_oct.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ec/ec_pmeth.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ec/ec_print.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ec/eck_prn.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ec/ecp_mont.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ec/ecp_nist.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ec/ecp_oct.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ec/ecp_smpl.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ecdh/ech_err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ecdh/ech_key.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ecdh/ech_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ecdsa/ecs_asn1.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ecdsa/ecs_err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ecdsa/ecs_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ecdsa/ecs_ossl.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ecdsa/ecs_sign.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ecdsa/ecs_vrf.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/engine/eng_all.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/engine/eng_cnf.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/engine/eng_ctrl.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/engine/eng_dyn.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/engine/eng_err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/engine/eng_fat.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/engine/eng_init.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/engine/eng_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/engine/eng_list.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/engine/eng_openssl.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/engine/eng_pkey.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/engine/eng_table.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/engine/tb_asnmth.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/engine/tb_cipher.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/engine/tb_dh.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/engine/tb_digest.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/engine/tb_dsa.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/engine/tb_ecdh.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/engine/tb_ecdsa.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/engine/tb_pkmeth.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/engine/tb_rand.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/engine/tb_rsa.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/engine/tb_store.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/err/err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/err/err_all.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/err/err_prn.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/bio_b64.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/bio_enc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/bio_md.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/c_all.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/digest.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/e_aes.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/e_aes_cbc_hmac_sha1.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/e_bf.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/e_camellia.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/e_cast.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/e_chacha.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/e_chacha20poly1305.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/e_des.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/e_des3.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/e_gost2814789.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/e_idea.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/e_null.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/e_old.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/e_rc2.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/e_rc4.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/e_rc4_hmac_md5.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/e_xcbc_d.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/encode.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/evp_aead.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/evp_enc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/evp_err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/evp_key.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/evp_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/evp_pbe.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/evp_pkey.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/m_dss.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/m_dss1.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/m_ecdsa.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/m_gost2814789.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/m_gostr341194.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/m_md4.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/m_md5.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/m_md5_sha1.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/m_null.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/m_ripemd.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/m_sha1.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/m_sigver.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/m_streebog.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/m_wp.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/names.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/p5_crpt.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/p5_crpt2.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/p_dec.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/p_enc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/p_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/p_open.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/p_seal.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/p_sign.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/p_verify.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/pmeth_fn.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/pmeth_gn.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp/pmeth_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/gost/gost2814789.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/gost/gost89_keywrap.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/gost/gost89_params.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/gost/gost89imit_ameth.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/gost/gost89imit_pmeth.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/gost/gost_asn1.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/gost/gost_err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/gost/gostr341001.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/gost/gostr341001_ameth.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/gost/gostr341001_key.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/gost/gostr341001_params.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/gost/gostr341001_pmeth.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/gost/gostr341194.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/gost/streebog.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/hkdf/hkdf.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/hmac/hm_ameth.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/hmac/hm_pmeth.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/hmac/hmac.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/idea/i_cbc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/idea/i_cfb64.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/idea/i_ecb.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/idea/i_ofb64.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/idea/i_skey.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/lhash/lh_stats.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/lhash/lhash.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/md4/md4_dgst.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/md4/md4_one.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/md5/md5_dgst.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/md5/md5_one.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/modes/cbc128.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/modes/ccm128.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/modes/cfb128.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/modes/ctr128.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/modes/cts128.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/modes/gcm128.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/modes/ofb128.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/modes/xts128.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/objects/o_names.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/objects/obj_dat.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/objects/obj_err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/objects/obj_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/objects/obj_xref.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ocsp/ocsp_asn.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ocsp/ocsp_cl.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ocsp/ocsp_err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ocsp/ocsp_ext.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ocsp/ocsp_ht.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ocsp/ocsp_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ocsp/ocsp_prn.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ocsp/ocsp_srv.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ocsp/ocsp_vfy.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pem/pem_all.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pem/pem_err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pem/pem_info.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pem/pem_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pem/pem_oth.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pem/pem_pk8.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pem/pem_pkey.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pem/pem_seal.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pem/pem_sign.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pem/pem_x509.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pem/pem_xaux.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pem/pvkfmt.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pkcs12/p12_add.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pkcs12/p12_asn.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pkcs12/p12_attr.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pkcs12/p12_crpt.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pkcs12/p12_crt.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pkcs12/p12_decr.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pkcs12/p12_init.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pkcs12/p12_key.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pkcs12/p12_kiss.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pkcs12/p12_mutl.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pkcs12/p12_npas.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pkcs12/p12_p8d.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pkcs12/p12_p8e.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pkcs12/p12_utl.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pkcs12/pk12err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pkcs7/bio_pk7.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pkcs7/pk7_asn1.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pkcs7/pk7_attr.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pkcs7/pk7_doit.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pkcs7/pk7_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pkcs7/pk7_mime.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pkcs7/pk7_smime.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/pkcs7/pkcs7err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/poly1305/poly1305.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rand/rand_err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rand/rand_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rand/randfile.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rc2/rc2_cbc.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rc2/rc2_ecb.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rc2/rc2_skey.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rc2/rc2cfb64.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rc2/rc2ofb64.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ripemd/rmd_dgst.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ripemd/rmd_one.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rsa/rsa_ameth.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rsa/rsa_asn1.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rsa/rsa_chk.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rsa/rsa_crpt.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rsa/rsa_depr.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rsa/rsa_eay.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rsa/rsa_err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rsa/rsa_gen.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rsa/rsa_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rsa/rsa_meth.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rsa/rsa_none.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rsa/rsa_oaep.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rsa/rsa_pk1.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rsa/rsa_pmeth.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rsa/rsa_prn.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rsa/rsa_pss.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rsa/rsa_saos.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rsa/rsa_sign.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/rsa/rsa_x931.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/sha/sha1_one.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/sha/sha1dgst.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/sha/sha256.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/sha/sha512.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/stack/stack.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ts/ts_asn1.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ts/ts_conf.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ts/ts_err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ts/ts_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ts/ts_req_print.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ts/ts_req_utils.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ts/ts_rsp_print.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ts/ts_rsp_sign.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ts/ts_rsp_utils.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ts/ts_rsp_verify.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ts/ts_verify_ctx.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/txt_db/txt_db.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ui/ui_err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ui/ui_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ui/ui_util.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/whrlpool/wp_dgst.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509/by_dir.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509/by_file.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509/by_mem.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509/x509_att.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509/x509_cmp.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509/x509_d2.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509/x509_def.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509/x509_err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509/x509_ext.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509/x509_lu.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509/x509_obj.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509/x509_r2x.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509/x509_req.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509/x509_set.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509/x509_trs.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509/x509_txt.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509/x509_v3.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509/x509_vfy.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509/x509_vpm.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509/x509cset.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509/x509name.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509/x509rset.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509/x509spki.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509/x509type.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509/x_all.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/pcy_cache.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/pcy_data.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/pcy_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/pcy_map.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/pcy_node.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/pcy_tree.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_akey.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_akeya.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_alt.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_bcons.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_bitst.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_conf.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_cpols.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_crld.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_enum.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_extku.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_genn.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_ia5.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_info.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_int.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_lib.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_ncons.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_ocsp.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_pci.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_pcia.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_pcons.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_pku.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_pmaps.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_prn.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_purp.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_skey.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_sxnet.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3_utl.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/x509v3/v3err.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bio/b_win.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/ui/ui_openssl_win.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/compat/posix_win.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/compat/bsd-asprintf.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/compat/freezero.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/compat/getpagesize.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/compat/reallocarray.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/compat/recallocarray.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/compat/strcasecmp.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/compat/strlcat.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/compat/strlcpy.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/compat/strndup.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/compat/strsep.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/compat/timegm.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/compat/explicit_bzero_win.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/compat/arc4random.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/compat/arc4random_uniform.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/compat/getentropy_win.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/compat/timingsafe_bcmp.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/compat/timingsafe_memcmp.c
)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/include")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/crypto")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/include/compat")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/asn1")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/bn")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/dsa")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/evp")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/modes")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src/ssl")

file(GLOB_RECURSE SSL_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/ssl/*.c)

install_include("${CMAKE_CURRENT_SOURCE_DIR}/src/include")

new_library_static(crypto "${CRYPTO_SOURCES}" "")
new_library_shared(crypto "${CRYPTO_SOURCES}" "")

if(WIN32)
	set(CRYPTO_UNEXPORT ${CRYPTO_UNEXPORT} BIO_s_log)

	set(EXTRA_EXPORT ${EXTRA_EXPORT} gettimeofday)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} posix_perror)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} posix_fopen)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} posix_fgets)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} posix_open)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} posix_rename)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} posix_connect)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} posix_close)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} posix_read)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} posix_write)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} posix_getsockopt)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} posix_setsockopt)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} sleep)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} asprintf)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} vasprintf)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} freezero)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} reallocarray)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} recallocarray)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} strcasecmp)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} strlcat)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} strlcpy)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} strndup)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} strnlen)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} strsep)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} timegm)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} explicit_bzero)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} arc4random)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} arc4random_buf)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} arc4random_uniform)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} getentropy)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} timingsafe_bcmp)
	set(EXTRA_EXPORT ${EXTRA_EXPORT} timingsafe_memcmp)
endif()

file(READ ${CMAKE_CURRENT_SOURCE_DIR}/src/crypto/crypto.sym SYMS)
foreach(SYM IN LISTS CRYPTO_UNEXPORT)
	string(REPLACE "${SYM}\n" "" SYMS ${SYMS})
endforeach()
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/crypto_p.sym ${SYMS})
if(EXTRA_EXPORT)
	list(SORT EXTRA_EXPORT)
	foreach(SYM IN LISTS EXTRA_EXPORT)
		file(APPEND ${CMAKE_CURRENT_BINARY_DIR}/crypto_p.sym "${SYM}\n")
	endforeach()
endif()

export_symbol(crypto ${CMAKE_CURRENT_BINARY_DIR}/crypto_p.sym)

set_target_properties(crypto PROPERTIES RUNTIME_OUTPUT_NAME_DEBUG "crypto-${CRYPTO_MAJOR_VERSION}${RUNTIME_DEBUG_POSTFIX}")
set_target_properties(crypto PROPERTIES RUNTIME_OUTPUT_NAME_RELEASE "crypto-${CRYPTO_MAJOR_VERSION}${RUNTIME_RELEASE_POSTFIX}")

target_link_libraries(crypto shell32 comdlg32 ws2_32)

new_library_static(ssl "${SSL_SOURCES}" "")
new_library_shared(ssl "${SSL_SOURCES}" "")

export_symbol(ssl ${CMAKE_CURRENT_SOURCE_DIR}/src/ssl/ssl.sym)

set_target_properties(ssl PROPERTIES RUNTIME_OUTPUT_NAME_DEBUG "ssl-${SSL_MAJOR_VERSION}${RUNTIME_DEBUG_POSTFIX}")
set_target_properties(ssl PROPERTIES RUNTIME_OUTPUT_NAME_RELEASE "ssl-${SSL_MAJOR_VERSION}${RUNTIME_RELEASE_POSTFIX}")

target_link_libraries(ssl shell32 comdlg32 ws2_32 crypto)
