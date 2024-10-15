page 747 "VAT Clauses"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Clauses';
    PageType = List;
    SourceTable = "VAT Clause";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for a VAT clause, which is used to provide a VAT description associated with a sales line on a sales invoice, credit memo, or other sales document.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the descriptive text that is associated with a VAT clause.';
                }
                field("Description 2"; "Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional description of a VAT clause.';
                }
                field("SII Exemption Code"; "SII Exemption Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SII Exemption of the VAT clause.';
                }
            }
            systempart(Control6; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control7; Notes)
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
            action("&Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Setup';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "VAT Posting Setup";
                RunPageLink = "VAT Clause Code" = FIELD(Code);
                ToolTip = 'View or edit combinations of VAT business posting groups and VAT product posting groups.';
            }
            action("T&ranslation")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'T&ranslation';
                Image = Translation;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "VAT Clause Translations";
                RunPageLink = "VAT Clause Code" = FIELD(Code);
                ToolTip = 'View or edit translations for each VAT clause description in different languages.';
            }
            action("DescriptionByDocumentType")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Description by document type';
                Image = Invoice;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "VAT Clauses by Doc. Type";
                RunPageLink = "VAT Clause Code" = FIELD(Code);
                ToolTip = 'View or edit VAT clause descriptions by document type.';
            }
            action("E&xtended Texts")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E&xtended Texts';
                Image = Text;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Extended Text List";
                RunPageLink = "Table Name" = CONST ("VAT Clause"),
                              "No." = FIELD (Code);
                RunPageView = SORTING ("Table Name", "No.", "Language Code", "All Language Codes", "Starting Date", "Ending Date");
                ToolTip = 'View additional information that has been added to the description for the VAT clause.';
            }
        }
    }
}

