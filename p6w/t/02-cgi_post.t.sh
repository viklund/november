#!/bin/sh
# Use shell script here, because
# RAKUDO: Can`t modify %*ENV;

echo -n "foo=bar" |  
REQUEST_METHOD='POST' \
TEST_RESULT='{"foo" => "bar"}' \
TEST_NAME='Post foo=bar' \
./t/cgi_post_test; 

echo -n "foo=bar&boo=her" |  
REQUEST_METHOD='POST' \
TEST_RESULT='{"foo" => "bar", "boo" => "her"}' \
TEST_NAME='Post foo=bar&boo=her' \
./t/cgi_post_test; 

echo -n "test=foo&test=bar" |  
REQUEST_METHOD='POST' \
TEST_RESULT='{"test" => ["foo", "bar"] }' \
TEST_NAME='Post test=foo&test=bar' \
./t/cgi_post_test; 

echo -n "test=foo&test=bar&foo=bar" |  
REQUEST_METHOD='POST' \
TEST_RESULT='{"test" => ["foo", "bar"], "foo" => "bar"}' \
TEST_NAME='Post test=foo&test=bar&foo=bar' \
./t/cgi_post_test; 

echo -n "test=foo" |  
REQUEST_METHOD='POST' \
QUERY_STRING="boom=bar" \
TEST_RESULT='{"test" => "foo", "boom" => "bar" }' \
TEST_NAME='Post test=foo Get boom=bar (test get and post mix)' \
./t/cgi_post_test; 

echo -n "test=foo" |  
REQUEST_METHOD='POST' \
QUERY_STRING="test=bar" \
TEST_RESULT='{"test" => ["bar", "foo"] }' \
TEST_NAME='Post test=foo Get test=bar (test get and post mix)' \
./t/cgi_post_test; 
