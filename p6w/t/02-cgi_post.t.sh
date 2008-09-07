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

echo -n "foo=bar&foo=boo&gop=her" |  
REQUEST_METHOD='POST' \
TEST_RESULT='{"foo" => ["bar", "boo"], "gop" => "her"}' \
TEST_NAME='Post foo=bar&foo=boo&gop=her' \
./t/cgi_post_test; 


