namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Manufacturing.Comment;

page 99000786 "Production BOM"
{
    Caption = 'Production BOM';
    PageType = ListPlus;
    SourceTable = "Production BOM Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a description for the production BOM.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the manufacturing batch unit of measure.';
                    ShowMandatory = true;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the status of the production BOM.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                    Importance = Additional;
                }
                field("Version Nos."; Rec."Version Nos.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the version number series that the production BOM versions refer to.';
                }
                field(ActiveVersionCode; ActiveVersionCode)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Active Version';
                    Editable = false;
                    ToolTip = 'Specifies which version of the production BOM is valid.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ProdBOMVersion: Record "Production BOM Version";
                    begin
                        ProdBOMVersion.SetRange("Production BOM No.", Rec."No.");
                        ProdBOMVersion.SetRange("Version Code", ActiveVersionCode);
                        PAGE.RunModal(PAGE::"Production BOM Version", ProdBOMVersion);
                        ActiveVersionCode := VersionMgt.GetBOMVersion(Rec."No.", WorkDate(), true);
                    end;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the last date that was modified.';
                }
            }
            part(ProdBOMLine; "Production BOM Lines")
            {
                ApplicationArea = Manufacturing;
                SubPageLink = "Production BOM No." = field("No."),
                              "Version Code" = const('');
                SubPageView = sorting("Production BOM No.", "Version Code", "Line No.");
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Prod. BOM")
            {
                Caption = '&Prod. BOM';
                Image = BOM;
                action("Co&mments")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Manufacturing Comment Sheet";
                    RunPageLink = "Table Name" = const("Production BOM Header"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Versions)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Versions';
                    Image = BOMVersions;
                    RunObject = Page "Prod. BOM Version List";
                    RunPageLink = "Production BOM No." = field("No.");
                    ToolTip = 'View any alternate versions of the production BOM.';
                }
                action("Ma&trix per Version")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ma&trix per Version';
                    Image = ProdBOMMatrixPerVersion;
                    ToolTip = 'View a list of all versions and items and the used quantity per item of a production BOM. You can use the matrix to compare different production BOM versions concerning the used items per version.';

                    trigger OnAction()
                    var
                        BOMMatrixForm: Page "Prod. BOM Matrix per Version";
                    begin
                        BOMMatrixForm.Set(Rec);

                        BOMMatrixForm.RunModal();
                        Clear(BOMMatrixForm);
                    end;
                }
                action("Where-used")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Where-used';
                    Image = "Where-Used";
                    ToolTip = 'View a list of BOMs in which the item is used.';

                    trigger OnAction()
                    begin
                        ProdBOMWhereUsed.SetProdBOM(Rec, WorkDate());
                        ProdBOMWhereUsed.RunModal();
                        Clear(ProdBOMWhereUsed);
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Copy &BOM")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Copy &BOM';
                    Ellipsis = true;
                    Image = CopyBOM;
                    ToolTip = 'Copy an existing production BOM to quickly create a similar BOM.';

                    trigger OnAction()
                    begin
                        Rec.TestField("No.");
                        OnCopyBOMOnBeforeLookup(Rec, ProdBOMHeader);
                        if PAGE.RunModal(0, ProdBOMHeader) = ACTION::LookupOK then
                            ProductionBOMCopy.CopyBOM(ProdBOMHeader."No.", '', Rec, '');
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Copy &BOM_Promoted"; "Copy &BOM")
                {
                }
                actionref("Ma&trix per Version_Promoted"; "Ma&trix per Version")
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref(Versions_Promoted; Versions)
                {
                }
                actionref("Where-used_Promoted"; "Where-used")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Prod. BOM', Comment = 'Generated from the PromotedActionCategories property index 3.';

            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ActiveVersionCode := VersionMgt.GetBOMVersion(Rec."No.", WorkDate(), true);
    end;

    var
        ProdBOMHeader: Record "Production BOM Header";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
        VersionMgt: Codeunit VersionManagement;
        ProdBOMWhereUsed: Page "Prod. BOM Where-Used";
        ActiveVersionCode: Code[20];

    [IntegrationEvent(false, false)]
    local procedure OnCopyBOMOnBeforeLookup(var ToProductionBOMHeader: Record "Production BOM Header"; var FromProductionBOMHeader: Record "Production BOM Header")
    begin
    end;
}

