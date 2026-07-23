//+------------------------------------------------------------------+
//|                                                  Boot254.mq5     |
//|                  Improved Trend Scalper                          |
//+------------------------------------------------------------------+
#property copyright "Grok"
#property version   "1.05"
#property strict

#include <Trade\Trade.mqh>
CTrade trade;

input int    FastEMA       = 9;          // Fast EMA Period
input int    SlowEMA       = 21;         // Slow EMA Period
input int    ADXPeriod     = 14;         // ADX Period
input double ADXLevel      = 25.0;       // Minimum ADX for strong trend
input double RiskPercent   = 1.0;        // Risk % per trade
input int    MaxSpread     = 50;         // Maximum allowed spread
input int    MaxTrades     = 3;          // Maximum open trades

ulong MagicNumber = 20250723;

//+------------------------------------------------------------------+
int hFast, hSlow, hADX, hATR;

int OnInit()
{
   hFast = iMA(_Symbol, PERIOD_CURRENT, FastEMA, 0, MODE_EMA, PRICE_CLOSE);
   hSlow = iMA(_Symbol, PERIOD_CURRENT, SlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   hADX  = iADX(_Symbol, PERIOD_CURRENT, ADXPeriod);
   hATR  = iATR(_Symbol, PERIOD_CURRENT, 14);
   
   trade.SetExpertMagicNumber(MagicNumber);
   
   Print("=== Boot254 EA Started Successfully on ", _Symbol, " ===");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnTick()
{
   if(CountOpenTrades() >= MaxTrades) return;
   
   // Spread filter
   long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(spread > MaxSpread) return;
   
   // Get indicator values
   double fast[], slow[], adx[], atr[];
   if(CopyBuffer(hFast,0,1,3,fast) < 3) return;
   if(CopyBuffer(hSlow,0,1,3,slow) < 3) return;
   if(CopyBuffer(hADX,0,1,2,adx) < 2) return;
   if(CopyBuffer(hATR,0,1,1,atr) < 1) return;
   
   bool bullish = (fast[0] > slow[0]) && (adx[0] > ADXLevel);
   bool bearish = (fast[0] < slow[0]) && (adx[0] > ADXLevel);
   
   double lot = CalculateLotSize(atr[0]);
   
   if(bullish)
   {
      trade.Buy(lot, _Symbol, 0, 0, 0, "Boot254 BUY");
      Print("BUY Signal - Trend Strength: ", adx[0]);
   }
   
   if(bearish)
   {
      trade.Sell(lot, _Symbol, 0, 0, 0, "Boot254 SELL");
      Print("SELL Signal - Trend Strength: ", adx[0]);
   }
}

//+------------------------------------------------------------------+
double CalculateLotSize(double atr)
{
   double riskMoney = AccountInfoDouble(ACCOUNT_BALANCE) * RiskPercent / 100.0;
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double lot = riskMoney / (atr * 1.5 * tickValue);   // SL = 1.5 * ATR
   lot = NormalizeDouble(lot, 2);
   return MathMax(lot, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN));
}

//+------------------------------------------------------------------+
int CountOpenTrades()
{
   int count = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      if(PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         count++;
   }
   return count;
}
