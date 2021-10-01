interface "Inventory Adjustment"
{
    procedure SetFilterItem(var NewItem: Record Item)

    procedure SetJobUpdateProperties(SkipUpdateJobItemCost: Boolean)

    procedure SetProperties(NewIsOnlineAdjmt: Boolean; NewPostToGL: Boolean)

    procedure MakeMultiLevelAdjmt()
}