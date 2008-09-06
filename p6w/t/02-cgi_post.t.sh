#!/bin/sh
echo "foo=bar" |  
REQUEST_METHOD='POST' \
TEST_RESULT='{"foo" => "bar"}' \
TEST_NAME='Post foo=bar' \
./t/cgi_post_test; 

echo "foo=bar&boo=her" |  
REQUEST_METHOD='POST' \
TEST_RESULT='{"foo" => "bar", "boo" => "her\n"}' \
TEST_NAME='Post foo=bar&boo=her' \
./t/cgi_post_test; 

echo "foo=bar&foo=boo&boo=her" |  
REQUEST_METHOD='POST' \
TEST_RESULT='{"foo" => ["bar", "boo"], "boo" => "her"}' \
TEST_NAME='Post foo=bar&boo=her&foo=boo' \
./t/cgi_post_test; 


