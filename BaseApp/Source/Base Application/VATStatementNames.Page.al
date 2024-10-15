page 320 "VAT Statement Names"
{
    Caption = 'VAT Statement Names';
    DataCaptionExpression = DataCaption();
    PageType = List;
    SourceTable = "VAT Statement Name";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT statement name.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the VAT statement name.';
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
        area(processing)
        {
            action("Edit VAT Statement")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit VAT Statement';
                Image = SetupList;
                ToolTip = 'View or edit how to calculate your VAT settlement amount for a period.';

                trigger OnAction()
                begin
                    VATStmtManagement.TemplateSelectionFromBatch(Rec);
                end;
            }
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    ReportPrint.PrintVATStmtName(Rec);
                end;
            }
        }
        area(reporting)
        {
            action("EC Sales List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'EC Sales List';
                Image = "Report";
                RunObject = Report "EC Sales List";
                ToolTip = 'View, print, or save an overview of your sales to other EU countries/regions. You can use the information when you report to the customs and tax authorities.';
            }
            action("Periodic VAT Payment Communication")
            {
                ApplicationArea = VAT;
                Caption = 'Periodic VAT Payment Communication';
                Image = TaxPayment;
                RunObject = Report "VAT Payment Communication";
                ToolTip = 'Generates the Periodic VAT payment communication as an xml file. ';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Edit VAT Statement_Promoted"; "Edit VAT Statement")
                {
                }
                actionref("&Print_Promoted"; "&Print")
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        SetRange("Statement Template Name");
    end;

    trigger OnOpenPage()
    begin
        VATStmtManagement.OpenStmtBatch(Rec);
    end;

    var
        ReportPrint: Codeunit "Test Report-Print";
        VATStmtManagement: Codeunit VATStmtManagement;

    local procedure DataCaption(): Text[250]
    var
        VATStmtTmpl: Record "VAT Statement Template";
    begin
        if not CurrPage.LookupMode then
            if GetFilter("Statement Template Name") <> '' then
                if GetRangeMin("Statement Template Name") = GetRangeMax("Statement Template Name") then
                    if VATStmtTmpl.Get(GetRangeMin("Statement Template Name")) then
                        exit(VATStmtTmpl.Name + ' ' + VATStmtTmpl.Description);
    end;
}

