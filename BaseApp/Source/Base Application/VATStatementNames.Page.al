page 320 "VAT Statement Names"
{
    Caption = 'VAT Statement Names';
    DataCaptionExpression = DataCaption;
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
                field(Control1220034; Comments)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the number of comments for VAT statement.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field(Control1220035; Attachments)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the number of attachments for VAT statement.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
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
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'View or edit how to calculate your VAT settlement amount for a period.';

                trigger Onaction()
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
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger Onaction()
                begin
                    ReportPrint.PrintVATStmtName(Rec);
                end;
            }
            action(Comments)
            {
                ApplicationArea = VAT;
                Caption = 'Comments';
                Image = ViewComments;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "VAT Statement Comment Sheet";
                RunPageLink = "VAT Statement Template Name" = field("Statement Template Name"),
                              "VAT Statement Name" = field(Name);
                ToolTip = 'Specifies VAT statement comments.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                ObsoleteTag = '17.0';
                Visible = false;
            }
            action(Attachments)
            {
                ApplicationArea = VAT;
                Caption = 'Attachments';
                Image = Attachments;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "VAT Statement Attachment Sheet";
                RunPageLink = "VAT Statement Template Name" = field("Statement Template Name"),
                              "VAT Statement Name" = field(Name);
                ToolTip = 'Specifies VAT statement attachments.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                ObsoleteTag = '17.0';
                Visible = false;
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

