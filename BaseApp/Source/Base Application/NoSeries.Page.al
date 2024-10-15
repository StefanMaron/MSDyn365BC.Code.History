page 456 "No. Series"
{
    AdditionalSearchTerms = 'numbering,number series';
    ApplicationArea = Basic, Suite;
    Caption = 'No. Series';
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "No. Series";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number series code.';
                }
                field("No. Series Type"; "No. Series Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series type that is associated with the number series code.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the number series.';
                }
                field("VAT Register"; "VAT Register")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT register that is associated with the number series code.';
                }
                field("Reverse Sales VAT No. Series"; "Reverse Sales VAT No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the numbers series that must be used for a reverse sales VAT transaction.';
                }
                field("VAT Reg. Print Priority"; "VAT Reg. Print Priority")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the print priority that is associated with the VAT register.';
                }
                field(StartDate; StartDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Starting Date';
                    Editable = false;
                    ToolTip = 'Specifies the date from which this line applies.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        DrillDown;
                    end;
                }
                field(StartNo; StartNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Starting No.';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the first number in the series.';

                    trigger OnDrillDown()
                    begin
                        DrillDown;
                    end;
                }
                field(EndNo; EndNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ending No.';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the last number in the series.';

                    trigger OnDrillDown()
                    begin
                        DrillDown;
                    end;
                }
                field(LastDateUsed; LastDateUsed)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Last Date Used';
                    Editable = false;
                    ToolTip = 'Specifies the date when a number was most recently assigned from the number series.';

                    trigger OnDrillDown()
                    begin
                        DrillDown;
                    end;
                }
                field(LastNoUsed; LastNoUsed)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Last No. Used';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the last number that was used from the number series.';

                    trigger OnDrillDown()
                    begin
                        DrillDown;
                    end;
                }
                field(WarningNo; WarningNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Warning No.';
                    Editable = false;
                    ToolTip = 'Specifies the language name of the chart memo.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        DrillDown;
                    end;
                }
                field(IncrementByNo; IncrementByNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Increment-by No.';
                    Editable = false;
                    ToolTip = 'Specifies a number that represents the size of the interval by which the numbers in the series are spaced.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        DrillDown;
                    end;
                }
                field("Default Nos."; "Default Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether this number series will be used to assign numbers automatically.';
                }
                field("Manual Nos."; "Manual Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that you can enter numbers manually instead of using this number series.';
                }
                field("Date Order"; "Date Order")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies to check that numbers are assigned chronologically.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Series")
            {
                Caption = '&Series';
                Image = SerialNo;
                action(Lines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Lines';
                    Image = AllLines;
                    ToolTip = 'View or edit the number series lines.';

                    trigger OnAction()
                    begin
                        case "No. Series Type" of
                            "No. Series Type"::Normal:
                                begin
                                    NoSeriesLine.Reset;
                                    NoSeriesLine.SetRange("Series Code", Code);
                                    PAGE.RunModal(PAGE::"No. Series Lines", NoSeriesLine);
                                end;
                            "No. Series Type"::Sales:
                                begin
                                    NoSeriesLineSales.Reset;
                                    NoSeriesLineSales.SetRange("Series Code", Code);
                                    PAGE.RunModal(PAGE::"No. Series Lines Sales", NoSeriesLineSales);
                                end;
                            "No. Series Type"::Purchase:
                                begin
                                    NoSeriesLinePurchase.Reset;
                                    NoSeriesLinePurchase.SetRange("Series Code", Code);
                                    PAGE.RunModal(PAGE::"No. Series Lines Purchase", NoSeriesLinePurchase);
                                end;
                        end;
                    end;
                }
                action(Relationships)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Relationships';
                    Image = Relationship;
                    RunObject = Page "No. Series Relationships";
                    RunPageLink = Code = FIELD(Code);
                    ToolTip = 'View or edit the related number series.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        FormUpdateLine;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        FormUpdateLine;
    end;

    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        StartDate: Date;
        StartNo: Code[20];
        EndNo: Code[20];
        LastNoUsed: Code[20];
        WarningNo: Code[20];
        IncrementByNo: Integer;
        LastDateUsed: Date;
        NoSeriesLineSales: Record "No. Series Line Sales";
        NoSeriesLinePurchase: Record "No. Series Line Purchase";

    local procedure DrillDown()
    begin
        case "No. Series Type" of
            "No. Series Type"::Normal:
                begin
                    NoSeriesMgt.SetNoSeriesLineFilter(NoSeriesLine, Code, 0D);
                    if NoSeriesLine.Find('-') then;
                    NoSeriesLine.SetRange("Starting Date");
                    NoSeriesLine.SetRange(Open);
                    PAGE.RunModal(0, NoSeriesLine);
                    CurrPage.Update;
                end;
            "No. Series Type"::Sales:
                begin
                    NoSeriesMgt.SetNoSeriesLineSalesFilter(NoSeriesLineSales, Code, 0D);
                    if NoSeriesLineSales.Find('-') then;
                    NoSeriesLineSales.SetRange("Starting Date");
                    NoSeriesLineSales.SetRange(Open);
                    PAGE.RunModal(0, NoSeriesLineSales);
                    CurrPage.Update;
                end;
            "No. Series Type"::Purchase:
                begin
                    NoSeriesMgt.SetNoSeriesLinePurchaseFilter(NoSeriesLinePurchase, Code, 0D);
                    if NoSeriesLinePurchase.Find('-') then;
                    NoSeriesLinePurchase.SetRange("Starting Date");
                    NoSeriesLinePurchase.SetRange(Open);
                    PAGE.RunModal(0, NoSeriesLinePurchase);
                    CurrPage.Update;
                end;
        end;
    end;

    local procedure FormUpdateLine()
    begin
        case "No. Series Type" of
            "No. Series Type"::Normal:
                begin
                    NoSeriesMgt.SetNoSeriesLineFilter(NoSeriesLine, Code, 0D);
                    if not NoSeriesLine.Find('-') then
                        NoSeriesLine.Init;
                    StartDate := NoSeriesLine."Starting Date";
                    StartNo := NoSeriesLine."Starting No.";
                    EndNo := NoSeriesLine."Ending No.";
                    LastNoUsed := NoSeriesLine."Last No. Used";
                    WarningNo := NoSeriesLine."Warning No.";
                    IncrementByNo := NoSeriesLine."Increment-by No.";
                    LastDateUsed := NoSeriesLine."Last Date Used"
                end;
            "No. Series Type"::Sales:
                begin
                    NoSeriesMgt.SetNoSeriesLineSalesFilter(NoSeriesLineSales, Code, 0D);
                    if not NoSeriesLineSales.Find('-') then
                        NoSeriesLineSales.Init;
                    StartDate := NoSeriesLineSales."Starting Date";
                    StartNo := NoSeriesLineSales."Starting No.";
                    EndNo := NoSeriesLineSales."Ending No.";
                    LastNoUsed := NoSeriesLineSales."Last No. Used";
                    WarningNo := NoSeriesLineSales."Warning No.";
                    IncrementByNo := NoSeriesLineSales."Increment-by No.";
                    LastDateUsed := NoSeriesLineSales."Last Date Used"
                end;
            "No. Series Type"::Purchase:
                begin
                    NoSeriesMgt.SetNoSeriesLinePurchaseFilter(NoSeriesLinePurchase, Code, 0D);
                    if not NoSeriesLinePurchase.Find('-') then
                        NoSeriesLinePurchase.Init;
                    StartDate := NoSeriesLinePurchase."Starting Date";
                    StartNo := NoSeriesLinePurchase."Starting No.";
                    EndNo := NoSeriesLinePurchase."Ending No.";
                    LastNoUsed := NoSeriesLinePurchase."Last No. Used";
                    WarningNo := NoSeriesLinePurchase."Warning No.";
                    IncrementByNo := NoSeriesLinePurchase."Increment-by No.";
                    LastDateUsed := NoSeriesLinePurchase."Last Date Used"
                end;
        end;
    end;
}

