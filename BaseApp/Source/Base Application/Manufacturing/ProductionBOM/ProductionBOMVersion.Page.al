namespace Microsoft.Manufacturing.ProductionBOM;

page 99000809 "Production BOM Version"
{
    Caption = 'Production BOM Version';
    DataCaptionExpression = Rec.Caption();
    PageType = ListPlus;
    SourceTable = "Production BOM Version";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Version Code"; Rec."Version Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the version code of the production BOM.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a description for the production BOM version.';
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
                    ToolTip = 'Specifies the status of this production BOM version.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the starting date for this production BOM version.';
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies when the production BOM version card was last modified.';
                }
            }
            part(ProdBOMLine; "Production BOM Version Lines")
            {
                ApplicationArea = Manufacturing;
                SubPageLink = "Production BOM No." = field("Production BOM No."),
                              "Version Code" = field("Version Code");
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
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ve&rsion")
            {
                Caption = 'Ve&rsion';
                Image = Versions;
                action("Where-Used")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Where-Used';
                    Image = "Where-Used";
                    ToolTip = 'View a list of BOMs in which the item is used.';

                    trigger OnAction()
                    var
                        ProdBOMHeader: Record "Production BOM Header";
                        ProdBOMWhereUsed: Page "Prod. BOM Where-Used";
                    begin
                        ProdBOMHeader.Get(Rec."Production BOM No.");
                        ProdBOMWhereUsed.SetProdBOM(ProdBOMHeader, Rec."Starting Date");
                        ProdBOMWhereUsed.Run();
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
                action(CopyBOM)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Copy &BOM';
                    Image = CopyBOMHeader;
                    ToolTip = 'Copy an existing production BOM to quickly create a similar BOM.';

                    trigger OnAction()
                    begin
                        if not Confirm(Text000, false) then
                            exit;

                        ProdBOMHeader.Get(Rec."Production BOM No.");
                        ProductionBOMCopy.CopyBOM(Rec."Production BOM No.", '', ProdBOMHeader, Rec."Version Code");
                    end;
                }
                action("Copy BOM &Version")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Copy BOM &Version';
                    Ellipsis = true;
                    Image = CopyBOMVersion;
                    ToolTip = 'Copy an existing production BOM version to quickly create a similar BOM.';

                    trigger OnAction()
                    begin
                        ProductionBOMCopy.CopyFromVersion(Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CopyBOM_Promoted; CopyBOM)
                {
                }
                actionref("Copy BOM &Version_Promoted"; "Copy BOM &Version")
                {
                }
            }
        }
    }

    var
#pragma warning disable AA0074
        Text000: Label 'Copy from Production BOM?';
#pragma warning restore AA0074
        ProdBOMHeader: Record "Production BOM Header";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
}

