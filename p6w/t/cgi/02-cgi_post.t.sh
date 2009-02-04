#!/bin/sh
# Use shell script here, because
# RAKUDO: Can`t modify %*ENV;

echo -n "foo=bar" |  
REQUEST_METHOD='POST' \
SERVER_NAME='test.foo' \
TEST_RESULT='{"foo" => "bar"}' \
TEST_NAME='Post foo=bar' \
./t/cgi/cgi_post_test; 

echo -n "foo=bar&boo=her" |  
REQUEST_METHOD='POST' \
SERVER_NAME='test.foo' \
TEST_RESULT='{"foo" => "bar", "boo" => "her"}' \
TEST_NAME='Post foo=bar&boo=her' \
./t/cgi/cgi_post_test; 

echo -n "test=foo&test=bar" |  
REQUEST_METHOD='POST' \
SERVER_NAME='test.foo' \
TEST_RESULT='{"test" => ["foo", "bar"] }' \
TEST_NAME='Post test=foo&test=bar' \
./t/cgi/cgi_post_test; 

echo -n "test=foo&test=bar&foo=bar" |  
REQUEST_METHOD='POST' \
SERVER_NAME='test.foo' \
TEST_RESULT='{"test" => ["foo", "bar"], "foo" => "bar"}' \
TEST_NAME='Post test=foo&test=bar&foo=bar' \
./t/cgi/cgi_post_test; 

echo -n "test=foo" |  
REQUEST_METHOD='POST' \
SERVER_NAME='test.foo' \
QUERY_STRING="boom=bar" \
TEST_RESULT='{"test" => "foo", "boom" => "bar" }' \
TEST_NAME='Post test=foo Get boom=bar (test get and post mix)' \
./t/cgi/cgi_post_test; 

echo -n "test=foo" |  
REQUEST_METHOD='POST' \
SERVER_NAME='test.foo' \
QUERY_STRING="test=bar" \
TEST_RESULT='{"test" => ["bar", "foo"] }' \
TEST_NAME='Post test=foo Get test=bar (test get and post mix)' \
./t/cgi/cgi_post_test; 
