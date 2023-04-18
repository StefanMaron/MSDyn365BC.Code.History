enum 7001 "Price Amount Type"
{
    Extensible = true;
    value(0; Any)
    {
        Caption = 'Price & Discount';
    }
    value(17; Price)
    {
        Caption = 'Price';
    }
    value(19; Cost)
    {
        ObsoleteState = Pending;
        ObsoleteReason = 'AmountType::Cost is replaced by the combination of AmountType::Price with PriceType::Purchase.';
        ObsoleteTag = '17.0';
        Caption = '', Locked = true;
    }
    value(20; Discount)
    {
        Caption = 'Discount';
    }
}