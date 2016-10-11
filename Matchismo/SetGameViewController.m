//
//  SetGameViewController.m
//  Matchismo
//
//  Created by Bradford Bennett Jr on 9/28/15.
//  Copyright (c) 2015 Rennox, LLC. All rights reserved.
//

#import "SetGameViewController.h"
#import "SetCardView.h"

@interface SetGameViewController ()
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tap;
@property (strong, nonatomic) SetMatchingGame *cardGame;
@property (nonatomic) BOOL removeMatchingCards;
@end

@implementation SetGameViewController
#pragma mark - Definitions
static NSString *const NO_ACTION = @"NO ACITON";
static NSString *const MID_TURN = @"MID TURN";
static NSString *const MATCH = @"MATCH";
#define MAX_CARD_WIDTH 750.0
#define MAX_CARD_HEIGHT 1000.0
#define MIN_CARD_WIDTH 75.0
#define MIN_CARD_HEIGHT 100.0
#define NUMBER_OF_STARTING_CARDS 12

#pragma mark - View Controller life cycle
-(void)viewDidLoad{
    //set up the number of cards to play with and update the UI
    self.numberOfStartingCards = NUMBER_OF_STARTING_CARDS;
    self.cardGame.numberOfDealtCards = self.numberOfStartingCards;
    self.maxCardSize = CGSizeMake(MAX_CARD_WIDTH, MAX_CARD_HEIGHT);
    self.minCardSize = CGSizeMake(MIN_CARD_WIDTH, MIN_CARD_HEIGHT);
    self.removeMatchingCards = YES;

    //initalize the cardviews array
    [self cardViews];

    [super viewDidLoad];
}

#pragma mark - Lazy Instantiation
-(Deck *)createDeck{
    self.gameType = @"Set Cards";
    return [[SetCardDeck alloc]init];
}
-(SetMatchingGame *)cardGame{
    if (!_cardGame) {
        _cardGame = [[SetMatchingGame alloc]initWithDeck:[self createDeck]];
        self.cardGame.numberOfMatchingCards = 3;
    }
    return _cardGame;
}
- (IBAction)dealNewGame:(UIButton *)sender {
    self.cardGame = [[SetMatchingGame alloc]initWithDeck:[self createDeck]];
    self.cardGame.numberOfMatchingCards = 3;
    [super dealNewGame:sender];
}

//getter for cardViews array
-(NSMutableArray *)cardViews{
    NSMutableArray *cardViews = [super cardViews];

    //if there are no cards in the array initialize all the card views
    if (![cardViews count]) {
        //code to create the setcard views
        SetCardView *cardView;
        SetCard *card;
            //index = 0 here because this relates to the views on screen, not the remaining available deck in the cardGame.
        int index = 0;

        //only do if the inputs are valid
        if (self.grid.inputsAreValid) {
            for (NSUInteger row = 0; row < self.grid.rowCount; row++) {
                for (NSUInteger column = 0; column < self.grid.columnCount; column++) {
                    cardView = [[SetCardView alloc]initWithFrame:[self.grid frameOfCellAtRow:row inColumn:column]];
                    card = (SetCard *)[self.cardGame cardAtIndex:index];
                    cardView.shape = card.shape;
                    cardView.shade = card.shade;
                    cardView.color = card.color;
                    cardView.number = card.number;
                    [self.tap addTarget:cardView action:@selector(selectCard:)];
                    [cardViews addObject:cardView];
                    [self.gridView addSubview:cardView];
                    index++;
                    if (index >= self.numberOfStartingCards) return cardViews;  //return if the card views have been filled
                }
            }
        } else {
            UILabel *label = [[UILabel alloc]init];
            label.text = @"Inputs are invalid";
            [self.gridView addSubview:label];
        }
    }

    return cardViews;
}

#pragma mark - User Interface Updating
    //Adds cards to the view by increasing the number of dealt cards within the cardgame.  This feeds back to the updateGrid method in this VC which updates the grid with the new cards.  Checks for max number of cards and shows a warning text if you are over
#define ADD_CARDS 3
#define WARNING_X_POS 10
#define WARNING_Y_POS 10
#define WARNING_WIDTH 400
#define WARNING_HEIGHT 25
-(IBAction)addThreeCardsButton:(UIButton *)sender{
        //If there are no more cards left in the deck display a message that fades out saying there are no more cards
    if (self.cardGame.numberOfDealtCards >= [self.cardGame.cards count]) {
        UILabel *warning = [[UILabel alloc] initWithFrame:CGRectMake(WARNING_X_POS, WARNING_Y_POS, WARNING_WIDTH, WARNING_HEIGHT)];
        warning.text = @"No more cards in the deck";
        warning.textColor = [UIColor whiteColor];
        [self.view.window addSubview:warning];
        [UIView animateWithDuration:1.5 animations:^{
            warning.alpha = 0;
        }completion:^(BOOL finished){
            [warning removeFromSuperview];
        }];
        return;
    }
        //If there is room for all of the ADD_CARDS to be drawn, draw them
    if (self.cardGame.numberOfDealtCards <= [self.cardGame.cards count] - ADD_CARDS) { self.cardGame.numberOfDealtCards = self.cardGame.numberOfDealtCards + ADD_CARDS; }
        //If there is room for some cards, but less than ADD_CARDS, add the remaining cards
    if (self.cardGame.numberOfDealtCards > [self.cardGame.cards count] - ADD_CARDS && self.cardGame.numberOfDealtCards < [self.cardGame.cards count]) { self.cardGame.numberOfDealtCards += ([self.cardGame.cards count] - self.cardGame.numberOfDealtCards); }

    [self updateUI];
}

- (IBAction)selectCardsToMatch:(UITapGestureRecognizer *)sender {
    //evaluate each touch event to see which card was chosen, then send that card to the model
    for (SetCardView *cardView in self.cardViews) {
        if (CGRectContainsPoint(cardView.bounds, [sender locationInView:cardView])) {
            [self.cardGame chooseCardAtIndex:[self.cardViews indexOfObject:cardView]];
        }
    }
    [self updateUI];
}

-(void)updateUI{
    [super updateUI];
    [self updateGrid];
        //parse out actions depending on current game status
    if ([self.cardGame.status isEqualToString:MATCH]) { [self animateMatch]; }
    if ([self.cardGame.status isEqualToString:NO_ACTION]) { [self resetCards]; }
}

    //Update the grid values to accomodate more cards being dealt onto the screen and updating the viewing of the cards as they populate
-(void)updateGrid{
    if (self.grid.minimumNumberOfCells != self.cardGame.numberOfDealtCards) {
        self.grid.minimumNumberOfCells = self.cardGame.numberOfDealtCards;
        if (self.grid.inputsAreValid) {}; //doing this to validate and change the grid, not very tactfully
        [self.cardViews makeObjectsPerformSelector:(@selector(removeFromSuperview))];
        SetCardView *cardView;
        SetCard *card;
            //index = 0 here because this relates to the views on screen, not the remaining available deck in the cardGame.
        int index = 0;
        for (NSUInteger row = 0; row < self.grid.rowCount; row++) {
            for (NSUInteger column = 0; column < self.grid.columnCount; column++) {
                cardView = [[SetCardView alloc]initWithFrame:[self.grid frameOfCellAtRow:row inColumn:column]];
                card = (SetCard *)[self.cardGame cardAtIndex:index];
                cardView.shape = card.shape;
                cardView.shade = card.shade;
                cardView.color = card.color;
                cardView.number = card.number;
                [self.tap addTarget:cardView action:@selector(selectCard:)];
                [self.cardViews addObject:cardView];
                [self.gridView addSubview:cardView];
                index++;
                if (index >= self.cardGame.numberOfDealtCards) break;  //return if the card views have been filled
            }
            if (index >= self.cardGame.numberOfDealtCards) break;  //return if the card views have been filled
        }
    }
}

//when a match occurs in game, animate the cards
-(void)animateMatch{
        //Array to clean up the cards as they are removed from the game.  Do not touch the self.cardViews array while its being enumerated
    NSMutableArray *cardViewCleanUp = [[NSMutableArray alloc] init];
        //use a weakSelf version of our VC for the animation block below
        //__weak SetGameViewController *weakSelf = self;
    for (SetCardView *cardView in self.cardViews) {
        if (cardView.selected) {
            [UIView animateWithDuration:1.0 delay:0.5 options:UIViewAnimationOptionCurveEaseIn animations:^{
                //not working
                //cardView.transform = CGAffineTransformMakeTranslation(self.view.bounds.origin.x, self.view.bounds.origin.y);
                //cardView.transform = CGAffineTransformMakeTranslation(0, -1000);
                    //use a weak version of self to remove the cardView object after the transformation is complete
                    //[weakSelf.cardViews removeObject:cardView];
                    //[cardView removeMatchedCard:self.view.window.bounds];
                    //Add cardView to the clean up array to later remove these from self.cardViews
                [cardViewCleanUp addObject:cardView];
                cardView.center = CGPointMake(0, 0); //THIS WOOOOOOOOOOOOOOOOORKS!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                    //[cardView removeFromSuperview];
            } completion:nil];
        }
    }
    self.cardGame.match = NO;
}

    //Reset cards calls all cardviews in the window and resets them to the default non-selected position
-(void)resetCards{
        //this code will call a method within SetCardView to toggle selected state
    for (SetCardView *cardView in self.cardViews) {
        if (cardView.selected) { cardView performSelector:@selector(deselectCard:); }
    }
}
@end
