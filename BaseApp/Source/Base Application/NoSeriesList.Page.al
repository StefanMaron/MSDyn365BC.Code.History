page 571 "No. Series List"
{
    Caption = 'No. Series List';
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Navigate';
    RefreshOnActivate = true;
    SourceTable = "No. Series";

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
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the number series.';
                }
                field(StartDate; StartDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Starting Date';
                    Editable = false;
                    ToolTip = 'Specifies the date from which you want this number series to apply. You use this field if you want to start a new series at the beginning of a new period. You set up a number series line for each period. The program will automatically switch to the new series on the starting date.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        DrillDownActionOnPage;
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
                        DrillDownActionOnPage;
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
                        DrillDownActionOnPage;
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
                        DrillDownActionOnPage;
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
                        DrillDownActionOnPage;
                    end;
                }
                field(WarningNo; WarningNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Warning No.';
                    Editable = false;
                    ToolTip = 'Specifies when you want to receive a warning that the number series is running out. You enter a number from the series. The program will provide a warning when this number is reached. You can enter a maximum of 20 characters, both numbers and letters.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        DrillDownActionOnPage;
                    end;
                }
                field(IncrementByNo; IncrementByNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Increment-by No.';
                    Editable = false;
                    ToolTip = 'Specifies the value for incrementing the numeric part of the series.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        DrillDownActionOnPage;
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
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "No. Series Lines";
                    RunPageLink = "Series Code" = FIELD(Code);
                    ToolTip = 'Define additional information about the number series.';
                }
                action(Relationships)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Relationships';
                    Image = Relationship;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "No. Series Relationships";
                    RunPageLink = Code = FIELD(Code);
                    ToolTip = 'Define the relationship between number series.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateLine(StartDate, StartNo, EndNo, LastNoUsed, WarningNo, IncrementByNo, LastDateUsed);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        StartDate := 0D;
        StartNo := '';
        EndNo := '';
        LastNoUsed := '';
        WarningNo := '';
        IncrementByNo := 0;
        LastDateUsed := 0D;
    end;

    var
        StartDate: Date;
        StartNo: Code[20];
        EndNo: Code[20];
        LastNoUsed: Code[20];
        WarningNo: Code[20];
        IncrementByNo: Integer;
        LastDateUsed: Date;

    local procedure DrillDownActionOnPage()
    begin
        DrillDown;
        CurrPage.Update;
    end;
}

