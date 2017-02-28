//
//  ViewController.m
//  tableViewHTML
//
//  Created by Paul on 2017/2/27.
//  Copyright © 2017年 Paul. All rights reserved.
//

#import "ViewController.h"


#define ScreenWidth  [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height


@interface ViewController ()<UITableViewDelegate, UITableViewDataSource, UIWebViewDelegate>
/** maxContentOffSet_Y */
@property (nonatomic, assign) CGFloat maxContentOffSet_Y;
/** contentView */
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *webViewHeadView;
/** tableView */
@property (nonatomic, strong) UITableView *tableView;
/** webView */
@property (nonatomic, strong) UIWebView *webView;

@end

@implementation ViewController

static NSString *CellId = @"cellId";
- (UITableView *)tableView
{
    if(!_tableView){
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, self.contentView.bounds.size.height) style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.rowHeight = 40.f;
        
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 200)];
        headerView.backgroundColor = [UIColor blueColor];
        _tableView.tableHeaderView = headerView;
        
        UILabel *tabFootLab = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 60)];
        tabFootLab.text = @"继续拖动，查看图文详情";
        tabFootLab.textAlignment = NSTextAlignmentCenter;
//        tabFootLab.backgroundColor = [UIColor lightGrayColor];
        _tableView.tableFooterView = tabFootLab;
        
        // 注册 cell
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellId];
    }
    return _tableView;
}

- (UIWebView *)webView {
    if (_webView == nil) {
        _webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, self.tableView.contentSize.height, ScreenWidth, ScreenHeight)];
        _webView.backgroundColor = [UIColor whiteColor];
        _webView.delegate = self;
        _webView.scrollView.delegate = self;
        [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://baidu.com"]]];
        
    }
    return _webView;
}

- (UILabel *)webViewHeadView {
    if (_webViewHeadView == nil) {
        _webViewHeadView = [[UILabel alloc] init];
        _webViewHeadView.text = @"上拉，返回详情";
        _webViewHeadView.textAlignment = NSTextAlignmentCenter;
        _webViewHeadView.frame = CGRectMake(0, 0, ScreenWidth, 40);
        _webViewHeadView.alpha = 0.0f;
    }
    return _webViewHeadView;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.maxContentOffSet_Y = 40;
    [self loadContentView];
}

- (void)loadContentView
{
    self.contentView = [[UIView alloc] init];
    self.contentView.frame = self.view.bounds;
    self.contentView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.contentView];

    // 第一个 View
    [self.contentView addSubview:self.tableView];
    // 第二个 view
    [self.contentView addSubview:self.webView];
    
    [self.webView addSubview:self.webViewHeadView];
    [self.webViewHeadView bringSubviewToFront:self.contentView];
    
    
    // 开始监听 webView.scrollView 的偏移量
    [self.webView.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    
    // 监听 tableView的 headerView 的滚动
    [self.tableView addObserver:self forKeyPath:@"contentOffset" options:0 context:nil];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    
    if (object == self.tableView && [keyPath isEqualToString:@"contentOffset"]) {
        CGFloat height = -(self.tableView.contentInset.top + self.tableView.contentOffset.y);
        
        if (height <= 0) {
            self.tableView.backgroundColor = [UIColor whiteColor];
        }else {
            self.tableView.backgroundColor = [UIColor blueColor];

        }
        
        NSLog(@"%zd",height);
        
        
    }else if (object == self.webView.scrollView && [keyPath isEqualToString:@"contentOffset"]) {
        [self headLabelAnimation:[change[@"new"] CGPointValue].y];
        
    }else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"contentOffset"];
}

// MARK: -- 头部提示文本动画
- (void)headLabelAnimation:(CGFloat)offsetY {
    self.webViewHeadView.alpha = -offsetY/60;
     self.webViewHeadView.center = CGPointMake(ScreenWidth/2, -offsetY/2.f);
    // 图标翻转，表示已超过临界值，松手就会返回上页
    if (-offsetY > self.maxContentOffSet_Y) {
        self.webViewHeadView.text = @"释放,返回详情";
    } else {
        self.webViewHeadView.text = @"上拉,返回详情";
    }
}

#pragma mark -- scrollViewDelegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    CGFloat offsetY = scrollView.contentOffset.y;
    
    if([scrollView isKindOfClass:[UITableView class]]){ // tableView页面上面的滚动
        NSLog(@"tableView-----");
        // 能触发翻页的理想值:tableView整体的高度减去屏幕本身的高度
        CGFloat valueNum = _tableView.contentSize.height -ScreenHeight;
        
        if ((offsetY - valueNum) > self.maxContentOffSet_Y) {
            // 进入图文详情的动画
            [self goToDetailAnimation];
        }
        
    } else { // webView页面上面的滚动
        NSLog(@"webView----");
        if (offsetY < 0 && -offsetY > self.maxContentOffSet_Y) {
            // 返回基本详情界面的动画
            [self backToFirstPageAnimation];
        }
    }
    
}
// MARK: -- 进入详情的动画
- (void)goToDetailAnimation {
    [UIView animateWithDuration:0.75 delay:0.0 options:UIViewAnimationOptionLayoutSubviews animations:^{
        self.webView.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight);
        self.tableView.frame = CGRectMake(0, -self.contentView.bounds.size.height, ScreenWidth, self.contentView.bounds.size.height);
    } completion:^(BOOL finished) {
        
    }];
}
// MARK: -- 返回基本详情界面的动画
- (void)backToFirstPageAnimation {
    [UIView animateWithDuration:0.75 delay:0.0 options:UIViewAnimationOptionLayoutSubviews animations:^{
        self.tableView.frame = CGRectMake(0, 0, ScreenWidth, self.contentView.bounds.size.height);
        self.webView.frame = CGRectMake(0, _tableView.contentSize.height, ScreenWidth, ScreenHeight);
        
    } completion:^(BOOL finished) {
        
    }];

}

#pragma mark - UITaleViewDelegate and UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"第%zd行cell",indexPath.row];
    
    return cell;
}




@end
