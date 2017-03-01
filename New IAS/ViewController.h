//
//  ViewController.h
//  New IAS
//
//  Created by wyfnevermore on 2017/2/8.
//  Copyright © 2017年 wyfnevermore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController : UIViewController<CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDataSource, UITableViewDelegate,UIPickerViewDelegate,UIPickerViewDataSource>
{
        int init;
        int packageNo;//计数用，包个数
        int returnByteNo;//计数用，计算返回次数
        int statement;
        int isClickedDisconnected;
        char returnData[4000];
        bool isGetCb;
        bool isCbInited;
        double cb[864];
        double aBS[864];
        double intentsities[864];
        double waveLength[864];
        NSString *dataString;
        NSString *checkResult;
        NSString *projectIDStr;
        NSMutableString *funcJsonString;
        NSMutableString *connectDeviceCode;//mac地址
        NSArray *pickArray;
}


@property (weak, nonatomic) IBOutlet UILabel *Result;
@property (strong, nonatomic) CBCentralManager* myCentralManager;
@property (strong, nonatomic) NSMutableArray* myPeripherals;
@property (strong, nonatomic) CBPeripheral* myPeripheral;
@property (strong, nonatomic) NSMutableArray* nServices;
@property (strong, nonatomic) NSMutableArray* nDevices;
@property (strong, nonatomic) NSMutableArray* nCharacteristics;
@property (strong, nonatomic) CBCharacteristic* startscanCharacteristic;
@property (strong, nonatomic) CBCharacteristic* requestdataCharacteristic;

@property (weak, nonatomic) IBOutlet UILabel *averageNumber;
@property (weak, nonatomic) IBOutlet UIPickerView *numberPickView;
@property (weak, nonatomic) IBOutlet UIImageView *bg;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *battery;
@property (weak, nonatomic) IBOutlet UILabel *temperature;
@property (weak, nonatomic) IBOutlet UILabel *moisture;
@property (weak, nonatomic) IBOutlet UIImageView *light;
@property (weak, nonatomic) IBOutlet UIButton *connect;
@property (weak, nonatomic) IBOutlet UIButton *getCB;
@property (weak, nonatomic) IBOutlet UIButton *cleardata;
@property (weak, nonatomic) IBOutlet UIButton *startscan;
@property (weak, nonatomic) IBOutlet UIButton *pickDone;

- (IBAction)connect:(id)sender;
- (IBAction)getCB:(id)sender;
- (IBAction)cleardata:(id)sender;
- (IBAction)startscan:(id)sender;
- (IBAction)pickDone:(id)sender;

- (void)scanClick;
- (void)initData;
- (void)connectClick;
- (void)disconnect;
- (NSData*)dataWithHexstring:(NSString*)hexstring;
- (void)writeToPeripheral:(NSString*)data;
- (NSString*)hexadecimalString:(NSData*)data;

@end

