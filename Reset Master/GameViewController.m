//
//  ViewController.m
//  Reset Master
//
//  Created by Minh Luu on 4/2/14.
//  Copyright (c) 2014 Minh Luu. All rights reserved.
//

#import "GameViewController.h"
#import "CardView.h"
#import "SetCard.h"
#import "CardCell.h"
#import "FooterCell.h"
#import "PauseMenuTableViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface GameViewController () <UICollectionViewDataSource, UICollectionViewDelegate, SetGameModelDelegate, AVAudioPlayerDelegate>

@property (nonatomic, strong) SetGameModel *model;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDateFormatter *formatter;
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, weak) FooterCell *footerCell;

@property (nonatomic, strong) NSMutableArray *audioPlayers;

@end

@implementation GameViewController

- (IBAction)drawCards:(id)sender {
    [self.model drawThreeCards];
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self.collectionView numberOfItemsInSection:0] - 1 inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
    
}

- (void)correctMatch {
    NSURL *soundUrl = [[NSBundle mainBundle] URLForResource:@"success" withExtension:@"m4a"];
    AVAudioPlayer *sound = [[AVAudioPlayer alloc] initWithContentsOfURL:soundUrl error:nil];
    [sound prepareToPlay];
    [sound play];
    [self.audioPlayers addObject:sound];
}

- (void)incorrectMatch {
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    NSURL *soundUrl = [[NSBundle mainBundle] URLForResource:@"incorrect" withExtension:@"wav"];
    AVAudioPlayer *sound = [[AVAudioPlayer alloc] initWithContentsOfURL:soundUrl error:nil];
    [sound prepareToPlay];
    [sound play];
    [self.audioPlayers addObject:sound];
    
    self.startTime = [self.startTime dateByAddingTimeInterval:-10];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationItem.hidesBackButton = YES;
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.model = [[SetGameModel alloc] initWithGameMode:self.mode];
    self.model.delegate = self;
    
    self.startTime = [NSDate date];
    self.formatter = [[NSDateFormatter alloc] init];
    self.formatter.dateFormat = NSDateFormatterNoStyle;
    self.formatter.timeStyle = NSDateFormatterShortStyle;
    
    self.audioPlayers= [@[] mutableCopy];

}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self.audioPlayers removeObject:player];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.timer invalidate];
}

- (void)viewWillAppear:(BOOL)animated {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
    [self.timer fire];
}

- (void)updateTime {
    NSInteger diff = -(NSInteger)[self.startTime timeIntervalSinceNow];
    NSInteger seconds = diff % 60;
    NSInteger minutes = (diff / 60) % 60;
    self.title = [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
}

#pragma Collection View Data Source & Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.model numPlayCards];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CardCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"Card Cell" forIndexPath:indexPath];
    SetCard *setCard = [self.model cardAtIndex:indexPath.item];
    cell.cardView.setCard = setCard;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.model selectCardAtIndex:indexPath.item];
    
    NSURL *selectURL = [[NSBundle mainBundle] URLForResource:@"select4" withExtension:@"mp3"];
    AVAudioPlayer *selectSound = [[AVAudioPlayer alloc] initWithContentsOfURL:selectURL error:nil];
    [selectSound prepareToPlay];
    [selectSound play];
    [self.audioPlayers addObject:selectSound];
    
}

- (void)updateCardsLeftLabel {
    self.footerCell.textLabel.text = [NSString stringWithFormat:@"%i cards left", self.model.cardsLeft];
}

- (void)removeCellAtIndexPaths:(NSArray *)indexPaths {
    [self.collectionView deleteItemsAtIndexPaths:indexPaths];
    

}

- (void)insertCellAtIndexPaths:(NSArray *)indexPaths {
    [self.collectionView insertItemsAtIndexPaths:indexPaths];
    [self updateCardsLeftLabel];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    self.footerCell = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Footer" forIndexPath:indexPath];
    [self updateCardsLeftLabel];
    return  self.footerCell;
}

#define COLLECTION_VIEW_MARGIN 8
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(COLLECTION_VIEW_MARGIN, COLLECTION_VIEW_MARGIN, 0, COLLECTION_VIEW_MARGIN);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    PauseMenuTableViewController *pauseVC = segue.destinationViewController;
    pauseVC.sets = [self.model foundSets];
    pauseVC.startTime = self.startTime;
}

@end
