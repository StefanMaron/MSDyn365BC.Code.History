page 7609 "Monthly Calendar"
{
    Caption = 'Monthly Calendar';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = Date;
    SourceTableView = WHERE("Period Type" = CONST(Week));

    layout
    {
    }

    actions
    {
    }
}

