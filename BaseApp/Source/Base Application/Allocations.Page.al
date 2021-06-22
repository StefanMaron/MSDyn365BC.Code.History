page 284 Allocations
{
    AutoSplitKey = true;
    Caption = 'Allocations';
    DataCaptionFields = "Journal Batch Name";
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Line,Account';
    SourceTable = "Gen. Jnl. Allocation";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the account number that the allocation will be posted to.';

                    trigger OnValidate()
                    begin
                        ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field("Account Name"; "Account Name")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the account that the allocation will be posted to.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(4),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(5),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(6),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(7),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(8),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
                field("Gen. Posting Type"; "Gen. Posting Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the type of transaction.';
                }
                field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                }
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    Visible = false;
                }
                field("Allocation Quantity"; "Allocation Quantity")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the quantity that will be used to calculate the amount in the allocation journal line.';

                    trigger OnValidate()
                    begin
                        AllocationQuantityOnAfterValid;
                    end;
                }
                field("Allocation %"; "Allocation %")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the percentage that will be used to calculate the amount in the allocation journal line.';

                    trigger OnValidate()
                    begin
                        Allocation37OnAfterValidate;
                    end;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amount that will be posted from the allocation journal line.';

                    trigger OnValidate()
                    begin
                        AmountOnAfterValidate;
                    end;
                }
            }
            group(Control18)
            {
                ShowCaption = false;
                fixed(Control1902205101)
                {
                    ShowCaption = false;
                    group(Control1903867001)
                    {
                        Caption = 'Amount';
                        field("AllocationAmount + Amount - xRec.Amount"; AllocationAmount + Amount - xRec.Amount)
                        {
                            ApplicationArea = All;
                            AutoFormatExpression = GetCurrencyCode;
                            AutoFormatType = 1;
                            Caption = 'AllocationAmount';
                            Editable = false;
                            ToolTip = 'Specifies the total amount that has been entered in the allocation journal up to the line where the cursor is.';
                            Visible = AllocationAmountVisible;
                        }
                    }
                    group("Total Amount")
                    {
                        Caption = 'Total Amount';
                        field(TotalAllocationAmount; TotalAllocationAmount + Amount - xRec.Amount)
                        {
                            ApplicationArea = All;
                            AutoFormatExpression = GetCurrencyCode;
                            AutoFormatType = 1;
                            Caption = 'Total Amount';
                            Editable = false;
                            ToolTip = 'Specifies the total amount that is allocated in the allocation journal.';
                            Visible = TotalAllocationAmountVisible;
                        }
                    }
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
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                        CurrPage.SaveRecord;
                    end;
                }
            }
            group("A&ccount")
            {
                Caption = 'A&ccount';
                Image = ChartOfAccounts;
                action(Card)
                {
                    ApplicationArea = Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "G/L Account Card";
                    RunPageLink = "No." = FIELD("Account No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the allocation.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Suite;
                    Caption = 'Ledger E&ntries';
                    Image = GLRegisters;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "General Ledger Entries";
                    RunPageLink = "G/L Account No." = FIELD("Account No.");
                    RunPageView = SORTING("G/L Account No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateAllocationAmount;
    end;

    trigger OnAfterGetRecord()
    begin
        ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnInit()
    begin
        TotalAllocationAmountVisible := true;
        AllocationAmountVisible := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        UpdateAllocationAmount;
        Clear(ShortcutDimCode);
    end;

    var
        AllocationAmount: Decimal;
        TotalAllocationAmount: Decimal;
        ShowAllocationAmount: Boolean;
        ShowTotalAllocationAmount: Boolean;
        ShortcutDimCode: array[8] of Code[20];
        [InDataSet]
        AllocationAmountVisible: Boolean;
        [InDataSet]
        TotalAllocationAmountVisible: Boolean;

    local procedure UpdateAllocationAmount()
    var
        TempGenJnlAlloc: Record "Gen. Jnl. Allocation";
    begin
        TempGenJnlAlloc.CopyFilters(Rec);
        ShowTotalAllocationAmount := TempGenJnlAlloc.CalcSums(Amount);
        if ShowTotalAllocationAmount then begin
            TotalAllocationAmount := TempGenJnlAlloc.Amount;
            if "Line No." = 0 then
                TotalAllocationAmount := TotalAllocationAmount + xRec.Amount;
        end;

        if "Line No." <> 0 then begin
            TempGenJnlAlloc.SetRange("Line No.", 0, "Line No.");
            ShowAllocationAmount := TempGenJnlAlloc.CalcSums(Amount);
            if ShowAllocationAmount then
                AllocationAmount := TempGenJnlAlloc.Amount;
        end else begin
            TempGenJnlAlloc.SetRange("Line No.", 0, xRec."Line No.");
            ShowAllocationAmount := TempGenJnlAlloc.CalcSums(Amount);
            if ShowAllocationAmount then begin
                AllocationAmount := TempGenJnlAlloc.Amount;
                TempGenJnlAlloc.CopyFilters(Rec);
                TempGenJnlAlloc := xRec;
                if TempGenJnlAlloc.Next = 0 then
                    AllocationAmount := AllocationAmount + xRec.Amount;
            end;
        end;

        AllocationAmountVisible := ShowAllocationAmount;
        TotalAllocationAmountVisible := ShowTotalAllocationAmount;
    end;

    local procedure AllocationQuantityOnAfterValid()
    begin
        CurrPage.Update(false);
    end;

    local procedure Allocation37OnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure AmountOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;
}

