page 7000068 "Posted Bills Analysis"
{
    Caption = 'Posted Bills Analysis';
    DataCaptionExpression = Caption();
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SourceTable = "Posted Cartera Doc.";

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(CategoryFilter; CategoryFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Category Filter';
                    TableRelation = "Category Code";
                    ToolTip = 'Specifies the categories that the data is included for.';

                    trigger OnValidate()
                    begin
                        CategoryFilterOnAfterValidate();
                    end;
                }
            }
            group(Control16)
            {
                ShowCaption = false;
                fixed(Control1902454701)
                {
                    ShowCaption = false;
                    group("Number of Bills")
                    {
                        Caption = 'Number of Bills';
                        field(NoOpen; NoOpen)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Open';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is not processed yet. ';
                        }
                        field(NoHonored; NoHonored)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Honored';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is settled. ';
                        }
                        field(NoRejected; NoRejected)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Rejected';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is rejected.';
                        }
                        field(NoRedrawn; NoRedrawn)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Redrawn (o/Rejected)';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is recirculated because it was rejected when its due date arrived.';
                        }
                        field(BGPOAmtLCY; BGPOAmtLCY)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'BGPO Amount';
                            Editable = false;
                            ToolTip = 'Specifies the amount on the bill group or payment order.';
                        }
                        field(NoBillInBGPO; NoBillInBGPO)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Number of Bills';
                            Editable = false;
                            ToolTip = 'Specifies the number of bills included.';
                        }
                    }
                    group(Amount)
                    {
                        Caption = 'Amount';
                        field(OpenAmtLCY; OpenAmtLCY)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Open';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is not processed yet. ';
                        }
                        field(HonoredAmtLCY; HonoredAmtLCY)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Closed';
                            Editable = false;
                            ToolTip = 'Specifies if the document is closed.';
                        }
                        field(RejectedAmtLCY; RejectedAmtLCY)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Rejected';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is rejected.';
                        }
                        field(RedrawnAmtLCY; RedrawnAmtLCY)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Editable = false;
                        }
                    }
                    group("%")
                    {
                        Caption = '%';
                        field(OpenPercentage; OpenPercentage)
                        {
                            ApplicationArea = Basic, Suite;
                            ExtendedDatatype = Ratio;
                            MaxValue = 100;
                            MinValue = 0;
                        }
                        field(HonoredPercentage; HonoredPercentage)
                        {
                            ApplicationArea = Basic, Suite;
                            ExtendedDatatype = Ratio;
                            MaxValue = 100;
                            MinValue = 0;
                        }
                        field(RejectedPercentage; RejectedPercentage)
                        {
                            ApplicationArea = Basic, Suite;
                            ExtendedDatatype = Ratio;
                            MaxValue = 100;
                            MinValue = 0;
                        }
                        field(RedrawnPercentage; RedrawnPercentage)
                        {
                            ApplicationArea = Basic, Suite;
                            ExtendedDatatype = Ratio;
                            MaxValue = 100;
                            MinValue = 0;
                        }
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        UpdateStatistics();
    end;

    trigger OnOpenPage()
    begin
        UpdateStatistics();
    end;

    var
        OpenAmtLCY: Decimal;
        HonoredAmtLCY: Decimal;
        RejectedAmtLCY: Decimal;
        RedrawnAmtLCY: Decimal;
        BGPOAmtLCY: Decimal;
        OpenPercentage: Decimal;
        RejectedPercentage: Decimal;
        HonoredPercentage: Decimal;
        RedrawnPercentage: Decimal;
        NoBillInBGPO: Integer;
        NoOpen: Integer;
        NoHonored: Integer;
        NoRejected: Integer;
        NoRedrawn: Integer;
        CategoryFilter: Code[10];

    local procedure UpdateStatistics()
    begin
        SetCurrentKey("Bank Account No.", "Bill Gr./Pmt. Order No.", Status, "Category Code", Redrawn, "Due Date", "Document Type");
        SetRange("Document Type", "Document Type"::Bill);
        if Type = Type::Receivable then
            SetRange(Type, Type::Receivable)
        else
            SetRange(Type, Type::Payable);

        if CategoryFilter = '' then
            SetRange("Category Code")
        else
            SetRange("Category Code", CategoryFilter);

        SetRange(Status);
        CalcSums("Amt. for Collection (LCY)");
        BGPOAmtLCY := "Amt. for Collection (LCY)";
        NoBillInBGPO := Count;

        SetRange(Status, Status::Open);
        CalcSums("Amt. for Collection (LCY)");
        OpenAmtLCY := "Amt. for Collection (LCY)";
        NoOpen := Count;

        if BGPOAmtLCY = 0 then
            OpenPercentage := 0
        else
            OpenPercentage := OpenAmtLCY / BGPOAmtLCY * 100;

        SetRange(Status);
        SetRange(Redrawn, true);
        CalcSums("Amt. for Collection (LCY)");
        RedrawnAmtLCY := "Amt. for Collection (LCY)";
        NoRedrawn := Count;

        SetRange(Redrawn);

        SetRange(Status, Status::Honored);
        CalcSums("Amt. for Collection (LCY)");
        HonoredAmtLCY := "Amt. for Collection (LCY)" - RedrawnAmtLCY;
        NoHonored := Count - NoRedrawn;

        if BGPOAmtLCY = 0 then
            HonoredPercentage := 0
        else
            HonoredPercentage := HonoredAmtLCY / BGPOAmtLCY * 100;

        SetRange(Status);

        SetRange(Status, Status::Rejected);
        CalcSums("Amt. for Collection (LCY)");
        RejectedAmtLCY := "Amt. for Collection (LCY)" + RedrawnAmtLCY;
        NoRejected := Count + NoRedrawn;

        if BGPOAmtLCY = 0 then
            RejectedPercentage := 0
        else
            RejectedPercentage := RejectedAmtLCY / BGPOAmtLCY * 100;

        if RejectedAmtLCY = 0 then
            RedrawnPercentage := 0
        else
            RedrawnPercentage := RedrawnAmtLCY / RejectedAmtLCY * 100;

        SetRange(Status);
    end;

    local procedure CategoryFilterOnAfterValidate()
    begin
        UpdateStatistics();
    end;
}

