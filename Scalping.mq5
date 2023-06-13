#include <Trade\Trade.mqh>

CTrade trade;
int ma21Handle, ma50Handle, ma200Handle;
double ma21[], ma50[], ma200[];
double fastMa, middleMa, slowMa;
int rsiHandle;
double rsiArray[], rsi;
int fractalhandle;
double upperFractalArray[], lowerFractalArray[];
double upperFractal, lowerFractal;
bool isBullish, isBullish2;
bool isEngulfing;
int barsTotal;
int positionTotal;
bool isUptrend;
double lotSize = 0.01;


int OnInit()
  {
  barsTotal = iBars(_Symbol,PERIOD_CURRENT);
   return(INIT_SUCCEEDED);
  }
void OnDeinit(const int reason)
  {
   
  }
void OnTick()
  {
     //Get the 21 peroid moving average
     ma21Handle = iMA(_Symbol,PERIOD_CURRENT,21,0,MODE_SMMA,PRICE_CLOSE);
     CopyBuffer(ma21Handle,MAIN_LINE,0,1,ma21);
     fastMa = ma21[0];
     
     //Get the 50 peroid moving average
     ma50Handle = iMA(_Symbol,PERIOD_CURRENT,50,0,MODE_SMMA,PRICE_CLOSE);
     CopyBuffer(ma50Handle,MAIN_LINE,0,1,ma50);
     middleMa = ma50[0];
     
     //Get the 200 peroid moving average
     ma200Handle = iMA(_Symbol,PERIOD_CURRENT,200,0,MODE_SMMA,PRICE_CLOSE);
     CopyBuffer(ma200Handle,MAIN_LINE,0,1,ma200);
     slowMa = ma200[0];
     
     //Get RSI
     rsiHandle = iRSI(_Symbol,PERIOD_CURRENT,14,PRICE_CLOSE);
     CopyBuffer(rsiHandle,MAIN_LINE,0,1,rsiArray);
     rsi = rsiArray[0];
     
     //Get Fractals
     fractalhandle = iFractals(_Symbol,PERIOD_CURRENT);
     CopyBuffer(fractalhandle,UPPER_LINE,3,1,upperFractalArray);
     CopyBuffer(fractalhandle,LOWER_LINE,3,1,lowerFractalArray);
     if (upperFractalArray[0] != DBL_MAX){
      upperFractal = upperFractalArray[0];
     }
     if(lowerFractalArray[0] != DBL_MAX){
      lowerFractal = lowerFractalArray[0];
     }
     
     //Get Bullish Candles
     double currentCandleOpen = iOpen(NULL,PERIOD_CURRENT,0);
     double currentCandleClose = iClose(NULL,PERIOD_CURRENT,0);
     double lastCandleOpen = iOpen(NULL,PERIOD_CURRENT,1);
     double lastCandleClose = iClose(NULL,PERIOD_CURRENT,1);
     
     
     //Get Current Trend
     if (fastMa > slowMa){
         isUptrend = true;
     } else{
         isUptrend = false;
     }
     
     positionTotal = PositionsTotal();
     int currentBars = iBars(_Symbol,PERIOD_CURRENT);
     
     if (positionTotal == 0){
         if(isUptrend == true){
            currentCandleClose = iClose(NULL,PERIOD_CURRENT,0);
            if(currentCandleClose > upperFractal && upperFractal != 0.0){
               if(currentBars != barsTotal){
                  barsTotal = currentBars;
                  double candleClose = iClose(NULL,PERIOD_CURRENT,1);
                  double candleOpen = iOpen(NULL,PERIOD_CURRENT,1);
                  lastCandleClose = iClose(NULL,PERIOD_CURRENT,2);
                  lastCandleOpen = iOpen(NULL,PERIOD_CURRENT,2);
                  if (candleClose - candleOpen > lastCandleClose - lastCandleOpen){
                     isEngulfing = true;
                  } else {
                     isEngulfing = false;
                  }
                  if(rsi > 50 && isEngulfing == true){
                     trade.Buy(lotSize,_Symbol,0.0,0.0,0.0);
                     upperFractal = 0.0;
                  }
               }
            }
         } else {
            currentCandleClose = iClose(NULL,PERIOD_CURRENT,0);
            if(currentCandleClose < lowerFractal && lowerFractal != 0.0){
               if(currentBars != barsTotal){
                  barsTotal = currentBars;
                  double candleClose = iClose(NULL,PERIOD_CURRENT,1);
                  double candleOpen = iOpen(NULL,PERIOD_CURRENT,1);
                  lastCandleClose = iClose(NULL,PERIOD_CURRENT,2);
                  lastCandleOpen = iOpen(NULL,PERIOD_CURRENT,2);
                  if (candleOpen - candleClose > lastCandleOpen - lastCandleClose){
                     isEngulfing = true;
                  } else {
                     isEngulfing = false;
                  }
                  if(rsi < 50 && isEngulfing == true){
                     trade.Sell(lotSize,_Symbol,0.0,0.0,0.0);
                     lowerFractal = 0.0;
                  }
               }
            }
         } 
     } else {
          for (int i = 0; i < positionTotal; i++) {
             // Retrieve the ticket number of the position
             ulong ticket = PositionGetTicket(i);
             // Retrieve other position information using the ticket number
             double positionVolume = PositionGetDouble(POSITION_VOLUME);
             double positionPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
             double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
             double positionProfit = PositionGetDouble(POSITION_PROFIT);
             long positionType = PositionGetInteger(POSITION_TYPE);
             double positionStopLoss = PositionGetDouble(POSITION_SL);
             double pips = positionProfit/positionVolume;
             // Output the position information
             Print("Position ", i+1);
             Print("Ticket: ", ticket);
             Print("Volume: ", positionVolume);
             Print("Price: ", positionPrice);
             Print("Open Price: ", openPrice);
             Print("Profit: ", positionProfit);
             Print("Pips: ",  pips);
             Print("============================");
             if (positionType == POSITION_TYPE_BUY && positionStopLoss == 0.0){
                  trade.PositionModify(ticket,openPrice - 75,openPrice + 100);
             }
             if (positionType == POSITION_TYPE_SELL && positionStopLoss == 0.0){
                  trade.PositionModify(ticket,openPrice + 75,openPrice - 100);
             }
             if (pips >= 50){
                 trade.PositionClose(ticket);
             }
             if (pips <= -20){
                 trade.PositionClose(ticket);
             }
             if (positionType == POSITION_TYPE_BUY && positionPrice < lowerFractal){
                  trade.PositionClose(ticket);
             }
             if (positionType == POSITION_TYPE_SELL && positionPrice > upperFractal){
                  trade.PositionClose(ticket);
             }
         }
     }  
  }