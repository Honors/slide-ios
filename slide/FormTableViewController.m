//
//  FormTableViewController.m
//  slide
//
//  Created by Jack Dent on 10/09/2014.
//  Copyright (c) 2014 slide. All rights reserved.
//

#import "XLForm.h"
#import "FormTableViewController.h"
#import "AFHTTPRequestOperationManager.h"
#import "FieldsDataStore.h"
#import "AlternativePickerViewController.h"
#import "API.h"

@implementation FormTableViewController

- (void)initForm {
    _rows = [[NSMutableArray alloc] initWithCapacity:((NSArray *) _formData[@"fields"]).count];
    
    XLFormDescriptor * form;
    XLFormSectionDescriptor * section;
    XLFormRowDescriptor * row;
    
    form = [XLFormDescriptor formDescriptorWithTitle:@"Add Event"];
    
    // First section
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    NSArray *fields = _formData[@"form"][@"fields"];
    for( NSDictionary *fieldInfo in fields ) {
        NSDictionary *field = fieldInfo[@"field"];
        NSString *fieldType = field[@"typeName"];
        if(fieldType) {
            row = [XLFormRowDescriptor formRowDescriptorWithTag:@"notes" rowType:types[fieldType]];
            NSArray *values = [[FieldsDataStore sharedInstance] getField:field[@"id"] withConstraints:@[]];
            [self configureRow:row withType:fieldType title:field[@"name"] andValue:values.lastObject];
            values = [self uniqueValues:values];
            if( values.count > 1 && [self isTextField:fieldType] ) {
                AlternativePickerViewController *alts = [[AlternativePickerViewController alloc] initWithData:values forUpdate:^(NSString *choice) {
                    [row.cellConfig setValue:choice forKey:@"textField.text"];
                    [self reloadFormRow:row];
                }];
                [altViews addObject:alts];
                [row.cellConfig setObject:((AlternativePickerViewController *)altViews.lastObject).picker forKey:@"textField.inputView"];
                row.value = values.lastObject;
            }
            [_rows addObject:@{@"row": row, @"field": field}];
            [section addFormRow:row];
        } else {
            NSLog(@"Ignoring field with unresolved type.");
        }
    }
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"notes" rowType:XLFormRowDescriptorTypeButton];
    row.title = @"SEND";
    row.tag = @"sendButton";
    [section addFormRow:row];
    [row.cellConfigAtConfigure setObject:[UIColor colorWithRed:0.18 green:0.75 blue:0.41 alpha:1.0] forKey:@"backgroundColor"];
    [row.cellConfigAtConfigure setObject:[UIColor whiteColor] forKey:@"textLabel.color"];
    self.form = form;
}
- (void)send: (id)sender {
    // Read in the user's input.
    NSMutableDictionary *fieldValues = [[NSMutableDictionary alloc] initWithCapacity:_rows.count];
    NSMutableDictionary *postValues = [[NSMutableDictionary alloc] initWithCapacity:_rows.count];
    for( NSDictionary *field in _rows ) {
        XLFormRowDescriptor *row = field[@"row"];
        NSDictionary *fieldInfo = field[@"field"];
        if(row.value) {
            fieldValues[fieldInfo] = row.value;
            postValues[[NSString stringWithFormat:@"%@", fieldInfo[@"id"]]] = row.value;
        }
    }
    // Update the keystore
    [[FieldsDataStore sharedInstance] registerUserForm:_formData[@"form"] forUser:_formData[@"form"][@"user"] withPatch:fieldValues];
    // Push the response to the backend.
    [[API sharedInstance] postForm:_formId withValues:postValues onSuccess:^(id responseObject) {
        UIViewController *thanks = [self.storyboard instantiateViewControllerWithIdentifier:@"thanks"];
        NSMutableArray *controllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
        [controllers removeLastObject];
        [controllers addObject:thanks];
        
        [self.navigationController setViewControllers:controllers animated:YES];
    } onFailure:^(NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}
- (void)viewDidLoad {
    [self initialize];
    altViews = [[NSMutableArray alloc] initWithCapacity:255];
    [self initForm];
    self.navigationItem.title = _formData[@"form"][@"name"];
}
- (void)didSelectFormRow:(XLFormRowDescriptor *)formRow {
    if( [formRow.tag isEqualToString:@"sendButton"] ) {
        [self send:formRow];
    }
}

@end
