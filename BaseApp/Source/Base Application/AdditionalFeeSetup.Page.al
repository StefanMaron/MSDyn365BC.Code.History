page 1050 "Additional Fee Setup"
{
    Caption = 'Additional Fee Setup';
    DataCaptionExpression = PageCaption;
    PageType = List;
    SourceTable = "Additional Fee Setup";

    layout
    {
        area(content)
        {
            repeater(Control15)
            {
                ShowCaption = false;
                field("Charge Per Line"; "Charge Per Line")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that additional fees are calculated per document line.';
                    Visible = false;
                }
                field("Reminder Terms Code"; "Reminder Terms Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the reminder terms code for the reminder.';
                    Visible = false;
                }
                field("Reminder Level No."; "Reminder Level No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the total of the additional fee amounts on the reminder lines.';
                    Visible = false;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency that is used on the entry.';
                }
                field("Threshold Remaining Amount"; "Threshold Remaining Amount")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amount that remains before the additional fee is incurred.';
                }
                field("Additional Fee Amount"; "Additional Fee Amount")
                {
                    ApplicationArea = Suite;
                    CaptionClass = AddFeeCaptionExpression;
                    ToolTip = 'Specifies the line amount of the additional fee.';
                }
                field("Additional Fee %"; "Additional Fee %")
                {
                    ApplicationArea = Suite;
                    CaptionClass = AddFeePercCaptionExpression;
                    ToolTip = 'Specifies the percentage of the total amount that makes up the additional fee.';
                }
                field("Min. Additional Fee Amount"; "Min. Additional Fee Amount")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the lowest amount that a fee can be.';
                }
                field("Max. Additional Fee Amount"; "Max. Additional Fee Amount")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the highest amount that a fee can be.';
                }
            }
            part(Chart; "Additional Fee Chart")
            {
                ApplicationArea = Suite;
                Visible = ShowChart;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        if ShowChart then
            CurrPage.Chart.PAGE.UpdateData;
    end;

    trigger OnOpenPage()
    var
        ReminderLevel: Record "Reminder Level";
    begin
        ShowChart := ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::Windows;
        if ShowChart then begin
            ReminderLevel.Get("Reminder Terms Code", "Reminder Level No.");
            CurrPage.Chart.PAGE.SetViewMode(ReminderLevel, "Charge Per Line", false);
            CurrPage.Chart.PAGE.UpdateData;
        end;

        if "Charge Per Line" then
            PageCaption := AddFeePerLineTxt;

        PageCaption += ' ' + ReminderTermsTxt + ' ' + "Reminder Terms Code" + ' ' +
          ReminderLevelTxt + ' ' + Format("Reminder Level No.");

        if "Charge Per Line" then begin
            AddFeeCaptionExpression := AddFeeperLineCaptionTxt;
            AddFeePercCaptionExpression := AddFeeperLineCaptionTxt + ' %';
        end else begin
            AddFeeCaptionExpression := AddFeeCaptionTxt;
            AddFeePercCaptionExpression := AddFeeCaptionTxt + ' %';
        end;
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";
        PageCaption: Text;
        AddFeePerLineTxt: Label 'Additional Fee per Line Setup -';
        ReminderTermsTxt: Label 'Reminder Terms:';
        ReminderLevelTxt: Label 'Level:';
        ShowChart: Boolean;
        AddFeeCaptionExpression: Text;
        AddFeeperLineCaptionTxt: Label 'Additional Fee per Line';
        AddFeeCaptionTxt: Label 'Additional Fee';
        AddFeePercCaptionExpression: Text;
}

