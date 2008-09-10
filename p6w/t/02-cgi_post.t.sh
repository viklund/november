#!/bin/sh
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

