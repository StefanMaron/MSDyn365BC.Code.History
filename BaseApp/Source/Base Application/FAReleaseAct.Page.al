page 12474 "FA Release Act"
{
    Caption = 'FA Release Act';
    PageType = Document;
    PopulateAllFields = true;
    RefreshOnActivate = true;
    SourceTable = "FA Document Header";
    SourceTableView = SORTING("Document Type", "No.")
                      WHERE("Document Type" = CONST(Release));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Posting Description"; "Posting Description")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies any text that is entered to accompany the posting, for example for information to auditors.';
                }
                field("Reason Document No."; "Reason Document No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the source document that is the reason for the fixed asset release.';
                }
                field("Reason Document Date"; "Reason Document Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the date of the source document that is the reason for the fixed asset release. This information is used in fixed asset reports and entries.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("FA Posting Date"; "FA Posting Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the posting date of the related fixed asset transaction, such as a depreciation.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Posting No."; "Posting No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a posting number to use for the fixed asset act entry.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';

                    trigger OnValidate()
                    begin
                        ShortcutDimension1CodeOnAfterV;
                    end;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';

                    trigger OnValidate()
                    begin
                        ShortcutDimension2CodeOnAfterV;
                    end;
                }
            }
            part(ReleaseLines; "FA Release Act Subform")
            {
                ApplicationArea = FixedAssets;
                SubPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("No.");
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Act")
            {
                Caption = '&Act';
                action("Co&mments")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "FA Comments";
                    RunPageLink = "Document Type" = CONST(Release),
                                  "Document No." = FIELD("No."),
                                  "Document Line No." = CONST(0);
                }
                action(Dimensions)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;

                    trigger OnAction()
                    begin
                        ShowDocDim;
                    end;
                }
                action("Employee Si&gnatures")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Employee Si&gnatures';
                    Image = Signature;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Document Signatures";
                    RunPageLink = "Table ID" = CONST(12470),
                                  "Document Type" = FIELD("Document Type"),
                                  "Document No." = FIELD("No.");
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Copy Document")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Copy Document';
                    Ellipsis = true;
                    Image = CopyDocument;
                    Promoted = true;
                    PromotedCategory = Process;

                    trigger OnAction()
                    begin
                        CopyFADoc.SetFADocHeader(Rec);
                        CopyFADoc.RunModal;
                        CopyFADoc.GetFADocHeader(Rec);
                        CurrPage.Update(true);
                        Clear(CopyFADoc);
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("P&ost")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'P&ost';
                    Ellipsis = true;
                    Image = Post;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Codeunit "FA Document-Post (Yes/No)";
                    ShortCutKey = 'F9';
                    ToolTip = 'Record the related transaction in your books.';
                }
                action(Preview)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Preview';
                    ToolTip = 'Preview the full content of the document.';

                    trigger OnAction()
                    var
                        FADocumentPostYesNo: Codeunit "FA Document-Post (Yes/No)";
                    begin
                        FADocumentPostYesNo.Preview(Rec);
                    end;
                }
            }
        }
    }

    var
        CopyFADoc: Report "Copy FA Document";
        DocPrint: Codeunit "Document-Print";

    local procedure ShortcutDimension1CodeOnAfterV()
    begin
        CurrPage.ReleaseLines.PAGE.UpdateForm(true);
    end;

    local procedure ShortcutDimension2CodeOnAfterV()
    begin
        CurrPage.ReleaseLines.PAGE.UpdateForm(true);
    end;
}

