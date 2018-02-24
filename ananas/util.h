//
//  util.h
//  ananasExample
//
//  Created by jerry.yong on 2018/2/16.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#ifndef util_h
#define util_h
#import <Foundation/Foundation.h>
#import "ffi.h"
@class ANCStructDeclare;


inline static  char *removeTypeEncodingPrefix(char *typeEncoding){
	while (*typeEncoding == 'r' || // const
		   *typeEncoding == 'n' || // in
		   *typeEncoding == 'N' || // inout
		   *typeEncoding == 'o' || // out
		   *typeEncoding == 'O' || // bycopy
		   *typeEncoding == 'R' || // byref
		   *typeEncoding == 'V') { // oneway
		typeEncoding++; // cutoff useless prefix
	}
	return typeEncoding;
}

const char * ananas_str_append(const char *str1, const char *str2);
ffi_type *ananas_ffi_type_with_type_encoding(const char *typeEncoding);
size_t ananas_struct_size_with_encoding(const char *typeEncoding);
NSString * ananas_struct_name_with_encoding(const char *typeEncoding);
void ananas_struct_data_with_dic(void *structData, NSDictionary *dic, ANCStructDeclare *declare);
#endif /* util_h */
