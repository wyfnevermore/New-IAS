//
//  ViewController.m
//  New IAS
//
//  Created by wyfnevermore on 2017/2/8.
//  Copyright © 2017年 wyfnevermore. All rights reserved.
//

#import "ViewController.h"
#import "dlpdata.h"
#import "Styles.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController ()
@end

@implementation ViewController

//页面载入时
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self initData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//1.开始查看服务, 蓝牙开启
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            [_connect setTitle:@"连接设备" forState:UIControlStateNormal];
            NSLog(@"蓝牙已打开, 请扫描外设!");
            break;
        default:
            [_connect setTitle:@"请打开蓝牙" forState:UIControlStateNormal];
            break;
    }
}

//2.点击连接设备按钮时扫描周边设备
- (void)scanClick{
    NSLog(@"正在扫描外设...");
    [self.myCentralManager scanForPeripheralsWithServices:nil options:nil];
    if(_myPeripheral != nil){
        [_myCentralManager cancelPeripheralConnection:_myPeripheral];
    }
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds* NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.myCentralManager stopScan];
        NSLog(@"扫描超时,停止扫描!");
    });
}

//查到外设后的方法,peripherals
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    if ([peripheral.name containsString:@"NIR"]) {
        [_myPeripherals addObject:peripheral];
        NSInteger count = [_myPeripherals count];
        NSLog(@"my periphearls count : %ld\n", (long)count);
        switch (count) {
            case 0:
                [_connect setTitle:@"未搜索到设备" forState:UIControlStateNormal];
                break;
            case 1:
                _tableView.hidden = YES;
                _myPeripheral = [_myPeripherals objectAtIndex:0];
                [self connectClick];
                break;
            default:
                //加这个判断是因为有的时候会重复扫描
                if (_myPeripherals.count == 2 && _myPeripherals[0] == _myPeripherals[1]) {
                    _tableView.hidden = YES;
                    _myPeripheral = [_myPeripherals objectAtIndex:0];
                    [self connectClick];
                }else{
                    _tableView.hidden = NO;
                    [_tableView reloadData];
                }
                break;
        }
    }
}

//连接
- (void)connectClick{
    [self.myCentralManager connectPeripheral:self.myPeripheral options:nil];
}

//连接外设成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    [self.myPeripheral setDelegate:self];
    [self.myPeripheral discoverServices:nil];
    [_light setImage:[UIImage imageNamed:@"green"]];
    [_connect setTitle:@"断开连接" forState:UIControlStateNormal];
}

//已发现服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    NSLog(@"发现服务!");
    int i = 0;
    for(CBService* s in peripheral.services){
        [self.nServices addObject:s];
    }
    for(CBService* s in peripheral.services){
        NSLog(@"%d :服务 UUID: %@(%@)", i, s.UUID.data, s.UUID);
        i++;
        [peripheral discoverCharacteristics:nil forService:s];
        NSLog(@"扫描Characteristics...");
    }
}

//已发现characteristcs
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    for(CBCharacteristic* c in service.characteristics){
        NSLog(@"特征 UUID: %@ (%@)", c.UUID.data, c.UUID);
        if([c.UUID.UUIDString containsString:@"411D"]&&c.properties == 0x8){
            self.startscanCharacteristic = c;
            NSLog(@"找到WRITE : %@", c);
        }
        if([c.UUID.UUIDString containsString:@"411D"]&&c.properties == 0x10){
            [self.myPeripheral setNotifyValue:YES forCharacteristic:c];
            NSLog(@"找到NOTIFY : %@", c);
        }
        //再次写入
        if([c.UUID.UUIDString containsString:@"4127"]){
            self.requestdataCharacteristic = c;
            NSLog(@"找到WRITE : %@", c);
        }
        if([c.UUID.UUIDString containsString:@"4128"]){
            [self.myPeripheral setNotifyValue:YES forCharacteristic:c];
            NSLog(@"找到NOTIFY : %@", c);
        }
    }
}

//获取外设发来的数据,不论是read和notify,获取数据都从这个方法中读取
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    [peripheral readRSSI];
    if([characteristic.UUID.UUIDString containsString:@"411D"]&&characteristic.properties == 0x10){
        NSData* data = characteristic.value;
        NSString* value = [self hexadecimalString:data];
        if([value containsString:@"ff"]&&init == 1){
            NSUInteger len = [data length];
            Byte *byteData = (Byte*)malloc(len);
            memcpy(byteData, [data bytes], len);
            Byte dataArr[4];
            for (int i=0; i<4; i++) {
                dataArr[i] = byteData[i+1];
            }
            NSData * myData = [NSData dataWithBytes:dataArr length:4];
            [_myPeripheral writeValue:myData forCharacteristic:_requestdataCharacteristic type:CBCharacteristicWriteWithResponse];
            NSLog(@"characteristic : %@, data : %@,\nvalue : %@", characteristic, data, value);
        }
    }
    if([characteristic.UUID.UUIDString containsString:@"4128"]){
        packageNo = packageNo+1;
        NSData* data = characteristic.value;
        NSString* value = [self hexadecimalString:data];
        //NSLog(@"characteristic : %@", characteristic);
        //NSLog(@"\n%@\n 触发vlaue", value);
        //收到的byte数组
        NSUInteger len = [data length];
        Byte *byteData = (Byte*)malloc(len);
        memcpy(byteData, [data bytes], len);
        if (packageNo > 2) {
            for (int c = 0; c<len-1; c++) {
                returnData[returnByteNo] = byteData[c+1];
                if (returnByteNo == 3731) {
                    switch (statement) {
                        case 0:{
                            bool isGetDataCB = getDLPData(returnData,waveLength, cb);
                            NSLog(@"%d仪器自检完成！",isGetDataCB);
                            isCbInited = true;
                            init = 0;
                            break;
                        }
                        case 1:
                            bool isGetDataYP = getDLPData(returnData,waveLength, intentsities);
                            NSLog(@"%d样品检测完成！",isGetDataYP);
                            dataString = [self getAbs:cb mintentsities:intentsities];
                            [self getRestData];
                            init = 0;
                            break;
                    }
                }
                returnByteNo++;
            }
        }
    }
}


//处理采集的光谱数据转成NSString
- (NSString*)getAbs:(double[864])Cb mintentsities:(double[864])Intentsities{
    NSString *dataStr = @"";
    for (int i = 0; i < 864; i++) {
        if(Intentsities[i]==0){
            aBS[i] = 0;
        }else {
            if(Cb[i]<=0){
                aBS[i] = 0;
            }else if(Intentsities[i]<=0){
                aBS[i] = 0;
            }else {
                aBS[i] = Cb[i]/Intentsities[i];;
            }
        }
    }
    NSMutableArray *mutArr=[[NSMutableArray alloc]initWithCapacity:605];
    for (int g = 0; g<605; g++) {
        NSString *arritem = [NSString stringWithFormat:@"%.8f",aBS[g]];
        mutArr[g] = arritem;
        if (g == 604) {
            dataStr = [dataStr stringByAppendingFormat:@"%@", [mutArr objectAtIndex:g]];
        }else{
            dataStr = [dataStr stringByAppendingFormat:@"%@,", [mutArr objectAtIndex:g]];
        }
    }
    return dataStr;
}


//服务
-(void)getRestData{
    NSURL *url = [NSURL URLWithString:@"http://115.29.198.253:8088/WCF/Service/GetData"];
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    //设置参数
    //设置请求头
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    //设置请求体
    NSMutableDictionary *dicTest = @{@"Service" : @"SendSpectrumPakg",
                                     @"DeviceCode" : @"11",
                                     @"Data" : @{
                                             @"ProjectId" : projectIDStr,
                                             @"SpectrumData" : dataString
                                             }
                                     };
    NSData *data2 = [NSJSONSerialization dataWithJSONObject:dicTest options:NSJSONWritingPrettyPrinted error:nil];
    [request setHTTPBody:data2];
    //返回数据
    NSData *received = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    NSString *receData = [[NSString alloc]initWithData:received encoding:NSUTF8StringEncoding];
    NSLog(@"%@",receData);
    if ([receData containsString:@"异常"] && receData == nil) {
        NSLog(@"检测异常");
    }else{
        NSArray *arrys74= [receData componentsSeparatedByString:@"\""];
        NSString* str74=(NSString *)arrys74[3];
        NSLog(@"%@",str74);
        [_Result setText:str74];
    }
}

//断开连接
- (void)disconnect{
    [self.myCentralManager cancelPeripheralConnection:_myPeripheral];
}

//掉线时调用
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    if (isClickedDisconnected == 0) {
        [_myCentralManager connectPeripheral:_myPeripheral options:nil];
    }
    [_light setImage:[UIImage imageNamed:@"red"]];
    [_connect setTitle:@"连接设备" forState:UIControlStateNormal];
    NSLog(@"periheral has disconnect");
}

//连接外设失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"%@", error);
}

//向peripheral中写入数据
- (void)writeToPeripheral:(NSString *)data{
    if(!_startscanCharacteristic){
        NSLog(@"writeCharacteristic is nil!");
        return;
    }
    NSData* value = [self dataWithHexstring:data];
    [_myPeripheral writeValue:value forCharacteristic:_startscanCharacteristic type:CBCharacteristicWriteWithResponse];
}

//按钮控件
- (IBAction)connect:(id)sender {
    if ([_connect.currentTitle containsString:@"连接设备"]) {
        [_myCentralManager stopScan];
        if (_myPeripherals != nil) {
            _myPeripherals = nil;
            _myPeripherals = [NSMutableArray array];
            [_tableView reloadData];
        }
        [self scanClick];
        isClickedDisconnected = 0;
    }else if ([_connect.currentTitle containsString:@"断开连接"]){
        [self disconnect];
        isClickedDisconnected = 1;
    }
}

- (IBAction)getCB:(id)sender {
    //初始化
    packageNo = 1;
    returnByteNo = 0;
    init = 1;
    NSString* value = @"00";
    [self writeToPeripheral:value];
    statement = 0;
}

- (IBAction)cleardata:(id)sender {
}

- (IBAction)startscan:(id)sender {
    //初始化
    packageNo = 1;
    returnByteNo = 0;
    init = 1;
    NSString* value = @"00";
    [self writeToPeripheral:value];
    statement = 1;
}

- (IBAction)pickDone:(id)sender {
    _numberPickView.hidden = YES;
    _pickDone.hidden = YES;
}
//按钮控件

//将传入的NSData类型转换成NSString并返回
- (NSString*)hexadecimalString:(NSData *)data{
    NSString* result;
    const unsigned char* dataBuffer = (const unsigned char*)[data bytes];
    if(!dataBuffer){
        return nil;
    }
    NSUInteger dataLength = [data length];
    NSMutableString* hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for(int i = 0; i < dataLength; i++){
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    }
    result = [NSString stringWithString:hexString];
    return result;
}

//将传入的NSString类型转换成NSData并返回
- (NSData*)dataWithHexstring:(NSString *)hexstring{
    NSMutableData* data = [NSMutableData data];
    int idx;
    for(idx = 0; idx + 2 <= hexstring.length; idx += 2){
        NSRange range = NSMakeRange(idx, 2);
        NSString* hexStr = [hexstring substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    return data;
}

//tableview的方法,返回section个数
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

//tableview的方法,返回rows(行数)
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _myPeripherals.count;
}

//tableview的方法,返回cell的view
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    //为表格定义一个静态字符串作为标识符
    static NSString* cellId = @"cellId";
    //从IndexPath中取当前行的行号
    NSUInteger rowNo = indexPath.row;
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
    UILabel* labelName = (UILabel*)[cell viewWithTag:1];
    UILabel* labelUUID = (UILabel*)[cell viewWithTag:2];
    labelName.text = [[_myPeripherals objectAtIndex:rowNo] name];
    NSString* uuid = [NSString stringWithFormat:@"%@", [[_myPeripherals objectAtIndex:rowNo] identifier]];
    uuid = [uuid substringFromIndex:[uuid length] - 13];
    NSLog(@"%@", uuid);
    labelUUID.text = uuid;
    [cell setBackgroundColor:[UIColor clearColor]];
    return cell;
}

//tableview的方法,点击行时触发
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSUInteger rowNo = indexPath.row;
    //    NSLog(@"%lu", (unsigned long)rowNo);
    _tableView.hidden = YES;
    _myPeripheral = [_myPeripherals objectAtIndex:rowNo];
    [self connectClick];
}

//pickerView的方法
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
    //为了说明,在UIPickerView中有多少列`
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    NSInteger arrayCount = pickArray.count;
    return arrayCount;
    //为了说明每列有多少行`
}

- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    NSString *screenData = [pickArray objectAtIndex:row];
    return screenData;
    //载入数组数据
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    [_averageNumber setText:[pickArray objectAtIndex:row]];
    //选到当前行时执行
}

//label点击事件
-(void) labelTouchUpInside:(UITapGestureRecognizer *)recognizer{
    UILabel *label=(UILabel*)recognizer.view;
    _numberPickView.hidden = NO;
    _pickDone.hidden = NO;
    NSLog(@"%@被点击了",label.text);
}

-(void)initData{
    //给选择器添加代理
    self.myCentralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil options:nil];
    _myPeripherals = [NSMutableArray array];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    projectIDStr = @"74";
    [self.view bringSubviewToFront:_tableView];
    self.numberPickView.delegate = self;
    self.numberPickView.dataSource = self;
    pickArray = [[NSArray alloc] initWithObjects:@"1", @"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"10",nil];
    _averageNumber.userInteractionEnabled=YES;
    UITapGestureRecognizer *labelTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(labelTouchUpInside:)];
    [_averageNumber addGestureRecognizer:labelTapGestureRecognizer];
    _tableView.backgroundColor = [UIColor colorWithRed:244.0/255 green:245.0/255 blue:249.0/255 alpha:1];
    _tableView.hidden = YES;
    _numberPickView.hidden = YES;
    _pickDone.hidden = YES;
    [_connect setBackgroundColor:[UIColor blackColor]];
    [_connect setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _connect.layer.cornerRadius = 5.0;//圆角的弧度
    [_startscan setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_startscan setBackgroundColor:[UIColor colorWithRed:132.0/255 green:212.0/255 blue:248.0/255 alpha:1]];
    _startscan.layer.cornerRadius = 15.0;//圆角的弧度
    [_getCB setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_getCB setBackgroundColor:[UIColor colorWithRed:132.0/255 green:212.0/255 blue:248.0/255 alpha:1]];
    _getCB.layer.cornerRadius = 10.0;//圆角的弧度
    [_cleardata setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_cleardata setBackgroundColor:[UIColor colorWithRed:132.0/255 green:212.0/255 blue:248.0/255 alpha:1]];
    _cleardata.layer.cornerRadius = 10.0;//圆角的弧度
}

@end
