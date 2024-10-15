// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

page 457 "No. Series Lines"
{
    AutoSplitKey = true;
    Caption = 'No. Series Lines';
    DataCaptionFields = "Series Code";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "No. Series Line";
    SourceTableView = sorting("Series Code", "Starting Date", "Starting No.");

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Series Code"; Rec."Series Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series to which this line applies.';
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date from which you would like this line to apply.';
                }
                field("Starting No."; Rec."Starting No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first number in the series.';
                }
                field("Ending No."; Rec."Ending No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last number in the series.';
                }
                field("Last Date Used"; Rec."Last Date Used")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when a number was most recently assigned from the number series.';
                }
                field("Last No. Used"; Rec."Last No. Used")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last number that was used from the number series.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Warning No."; Rec."Warning No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when you want to receive a warning that the number series is running out.';
                }
                field("Increment-by No."; Rec."Increment-by No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the size of the interval by which you would like to space the numbers in the number series.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Allow Gaps in Nos."; Rec."Allow Gaps in Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that a number assigned from the number series can later be deleted. This is practical for records, such as item cards and warehouse documents that, unlike financial transactions, can be deleted and cause gaps in the number sequence. This setting also means that new numbers will be generated and assigned in a faster, non-blocking way. NOTE: If an error occurs on a new record that will be assigned a number from such a number series when it is completed, the number in question will be lost, causing a gap in the sequence.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(Open; Rec.Open)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the number series line is open. It is open until the last number in the series has been used.';
                }
                field(Series; Rec.Series)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the series of control numbers that are assigned by the tax authorities (SAT).';
                }
                field("Authorization Code"; Rec."Authorization Code")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the code assigned by the tax authorities for series and folio numbers.';
                }
                field("Authorization Year"; Rec."Authorization Year")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the year assigned by the tax authorities for series and folio numbers.';
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
    }

    trigger OnAfterGetCurrRecord()
    begin
        if Rec."Allow Gaps in Nos." then
            Rec."Last No. Used" := Rec.GetLastNoUsed();
    end;

    trigger OnAfterGetRecord()
    begin
        if Rec."Allow Gaps in Nos." then
            Rec."Last No. Used" := Rec.GetLastNoUsed();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        NoSeriesLine.Copy(Rec);
        if BelowxRec then
            if NoSeriesLine.FindLast() then begin
                Rec."Increment-by No." := NoSeriesLine."Increment-by No.";
                Rec."Allow Gaps in Nos." := NoSeriesLine."Allow Gaps in Nos.";
            end;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if NoSeriesLine.Get(Rec."Series Code", Rec."Line No.") then begin
            NoSeriesLine.SetRange("Series Code", Rec."Series Code");
            if NoSeriesLine.FindLast() then;
            Rec."Line No." := NoSeriesLine."Line No." + 10000;
        end;
        if Rec."Allow Gaps in Nos." and (Rec."Sequence Name" = '') then begin // delayed creation of sequence.
            Rec."Allow Gaps in Nos." := false;
            Rec.Validate("Allow Gaps in Nos.", true);
        end;
        exit(true);
    end;

    var
        NoSeriesLine: Record "No. Series Line";
}