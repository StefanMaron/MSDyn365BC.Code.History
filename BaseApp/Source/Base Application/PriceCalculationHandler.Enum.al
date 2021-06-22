enum 7011 "Price Calculation Handler" implements "Price Calculation"
{
    Extensible = true;
    value(0; "Not Defined")
    {
        Caption = 'Not Defined';
        Implementation = "Price Calculation" = "Price Calculation - V15";
    }
    value(7002; "Business Central (Version 16.0)")
    {
        Caption = 'Business Central (Version 16.0)', Locked = true;
        Implementation = "Price Calculation" = "Price Calculation - V16";
    }
    value(7003; "Business Central (Version 15.0)")
    {
        Caption = 'Business Central (Version 15.0)', Locked = true;
        Implementation = "Price Calculation" = "Price Calculation - V15";
        ObsoleteState = Pending;
        ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
        ObsoleteTag = '16.0';
    }
}