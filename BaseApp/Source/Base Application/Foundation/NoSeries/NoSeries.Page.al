// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.BatchProcessing;

using Microsoft.Utilities;

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
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number series code.';
                }
                field("No. Series Type"; Rec."No. Series Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series type that is associated with the number series code.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the number series.';
                }
                field("VAT Register"; Rec."VAT Register")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT register that is associated with the number series code.';
                }
                field("Reverse Sales VAT No. Series"; Rec."Reverse Sales VAT No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the numbers series that must be used for a reverse sales VAT transaction.';
                }
                field("VAT Reg. Print Priority"; Rec."VAT Reg. Print Priority")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the print priority that is associated with the VAT register.';
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
                        DrillDownActionOnPage();
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
                        DrillDownActionOnPage();
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
                        DrillDownActionOnPage();
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
                        DrillDownActionOnPage();
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
                        DrillDownActionOnPage();
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
                        DrillDownActionOnPage();
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
                        DrillDownActionOnPage();
                    end;
                }
                field("Default Nos."; Rec."Default Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether this number series will be used to assign numbers automatically.';
                }
                field("Manual Nos."; Rec."Manual Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that you can enter numbers manually instead of using this number series.';
                }
                field("Date Order"; Rec."Date Order")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies to check that numbers are assigned chronologically.';
                }
                field(AllowGapsCtrl; AllowGaps)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Allow Gaps in Nos.';
                    ToolTip = 'Specifies that a number assigned from the number series can later be deleted. This is practical for records, such as item cards and warehouse documents that, unlike financial transactions, can be deleted and cause gaps in the number sequence. This setting also means that new numbers will be generated and assigned in a faster, non-blocking way. NOTE: If an error occurs on a new record that will be assigned a number from such a number series when it is completed, the number in question will be lost, causing a gap in the sequence.';

                    trigger OnValidate()
                    begin
                        Rec.TestField(Code);
                        Rec.SetAllowGaps(AllowGaps);
                    end;
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
                        case Rec."No. Series Type" of
                            Rec."No. Series Type"::Normal:
                                begin
                                    NoSeriesLine.Reset();
                                    NoSeriesLine.SetRange("Series Code", Rec.Code);
                                    PAGE.RunModal(PAGE::"No. Series Lines", NoSeriesLine);
                                end;
                            Rec."No. Series Type"::Sales:
                                begin
                                    NoSeriesLineSales.Reset();
                                    NoSeriesLineSales.SetRange("Series Code", Rec.Code);
                                    PAGE.RunModal(PAGE::"No. Series Lines Sales", NoSeriesLineSales);
                                end;
                            Rec."No. Series Type"::Purchase:
                                begin
                                    NoSeriesLinePurchase.Reset();
                                    NoSeriesLinePurchase.SetRange("Series Code", Rec.Code);
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
                    RunPageLink = Code = field(Code);
                    ToolTip = 'View or edit relationships between number series.';
                }
            }
        }
        area(Processing)
        {
            action(TestNoSeries)
            {
                ApplicationArea = Basic, Suite;
                Image = TestFile;
                Caption = 'Test No. Series';
                ToolTip = 'Test whether the number series can generate new numbers.';

                trigger OnAction()
                var
                    NoSeries: Record "No. Series";
                    BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
                begin
                    CurrPage.SetSelectionFilter(NoSeries);
                    BatchProcessingMgt.BatchProcess(NoSeries, Codeunit::"No. Series Check", Enum::"Error Handling Options"::"Show Error", 0, 0);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Relationships_Promoted; Relationships)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateLineActionOnPage();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        UpdateLineActionOnPage();
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
        AllowGaps: Boolean;

    local procedure DrillDownActionOnPage()
    begin
        case Rec."No. Series Type" of
            Rec."No. Series Type"::Normal:
                begin
                    NoSeriesMgt.SetNoSeriesLineFilter(NoSeriesLine, Rec.Code, 0D);
                    if NoSeriesLine.Find('-') then;
                    NoSeriesLine.SetRange("Starting Date");
                    NoSeriesLine.SetRange(Open);
                    PAGE.RunModal(0, NoSeriesLine);
                    CurrPage.Update(false);
                end;
            Rec."No. Series Type"::Sales:
                begin
                    NoSeriesMgt.SetNoSeriesLineSalesFilter(NoSeriesLineSales, Rec.Code, 0D);
                    if NoSeriesLineSales.Find('-') then;
                    NoSeriesLineSales.SetRange("Starting Date");
                    NoSeriesLineSales.SetRange(Open);
                    PAGE.RunModal(0, NoSeriesLineSales);
                    CurrPage.Update(false);
                end;
            Rec."No. Series Type"::Purchase:
                begin
                    NoSeriesMgt.SetNoSeriesLinePurchaseFilter(NoSeriesLinePurchase, Rec.Code, 0D);
                    if NoSeriesLinePurchase.Find('-') then;
                    NoSeriesLinePurchase.SetRange("Starting Date");
                    NoSeriesLinePurchase.SetRange(Open);
                    PAGE.RunModal(0, NoSeriesLinePurchase);
                    CurrPage.Update(false);
                end;
        end;
    end;

    protected procedure UpdateLineActionOnPage()
    begin
        Rec.UpdateLine(StartDate, StartNo, EndNo, LastNoUsed, WarningNo, IncrementByNo, LastDateUsed, AllowGaps);
    end;
}
