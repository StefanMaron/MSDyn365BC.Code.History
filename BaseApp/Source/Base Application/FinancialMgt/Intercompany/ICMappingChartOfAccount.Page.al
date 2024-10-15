page 626 "IC Mapping Chart of Account"
{
    PageType = ListPlus;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Intercompany Chart of Accounts Mapping';

    layout
    {
        area(Content)
        {
            group(General)
            {
                ShowCaption = false;
                part(IntercompanyChartOfAccounts; "IC Mapping CoA Incoming")
                {
                    Caption = 'Intercompany Chart of Accounts';
                    ApplicationArea = All;
                }
                part(CurrentCompanyChartOfAccounts; "IC Mapping CoA Outgoing")
                {
                    Caption = 'G/L Chart of Accounts';
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                Image = "Action";
                action(MapICAccountsWithSameNo)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Map accounts with same no.';
                    Image = MapAccounts;
                    ToolTip = 'Map the selected accounts with the same number. Only accounts with the same account number and account type (e.g. Heading) are matched.';

                    trigger OnAction()
                    var
                        ICAccounts: Record "IC G/L Account";
                        GLAccounts: Record "G/L Account";
                        ICMappingAccounts: Codeunit "IC Mapping Accounts";
                        UserSelection: Integer;
                    begin
                        UserSelection := StrMenu(SelectionOptionsQst, 0, MapAccountsInstructionQst);
                        case UserSelection of
                            1:
                                begin
                                    CurrPage.IntercompanyChartOfAccounts.Page.GetSelectedLines(ICAccounts);
                                    ICMappingAccounts.MapICAccounts(ICAccounts);
                                end;
                            2:
                                begin

                                    CurrPage.CurrentCompanyChartOfAccounts.Page.GetSelectedLines(GLAccounts);
                                    ICMappingAccounts.MapCompanyAccounts(GLAccounts);
                                end;
                            3:
                                begin
                                    CurrPage.IntercompanyChartOfAccounts.Page.GetSelectedLines(ICAccounts);
                                    CurrPage.CurrentCompanyChartOfAccounts.Page.GetSelectedLines(GLAccounts);
                                    ICMappingAccounts.MapICAccounts(ICAccounts);
                                    ICMappingAccounts.MapCompanyAccounts(GLAccounts);
                                end;
                        end;
                    end;
                }
                action(RemoveMappingOfICAccounts)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Remove accounts mapping';
                    Image = UnLinkAccount;
                    ToolTip = 'Remove the existing mapping of the selected accounts.';

                    trigger OnAction()
                    var
                        ICAccounts: Record "IC G/L Account";
                        GLAccounts: Record "G/L Account";
                        ICMappingAccounts: Codeunit "IC Mapping Accounts";
                        UserSelection: Integer;
                    begin
                        UserSelection := StrMenu(SelectionOptionsQst, 0, RemoveMappingInstructionQst);
                        case UserSelection of
                            1:
                                begin
                                    CurrPage.IntercompanyChartOfAccounts.Page.GetSelectedLines(ICAccounts);
                                    ICMappingAccounts.RemoveICMapping(ICAccounts);
                                end;
                            2:
                                begin
                                    CurrPage.CurrentCompanyChartOfAccounts.Page.GetSelectedLines(GLAccounts);
                                    ICMappingAccounts.RemoveCompanyMapping(GLAccounts);
                                end;
                            3:
                                begin
                                    CurrPage.IntercompanyChartOfAccounts.Page.GetSelectedLines(ICAccounts);
                                    CurrPage.CurrentCompanyChartOfAccounts.Page.GetSelectedLines(GLAccounts);
                                    ICMappingAccounts.RemoveICMapping(ICAccounts);
                                    ICMappingAccounts.RemoveCompanyMapping(GLAccounts);
                                end;
                        end;
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(MapICAccountsWithSameNo_Promoted; MapICAccountsWithSameNo)
                {
                }
                actionref(RemoveMappingOfICAccounts_Promoted; RemoveMappingOfICAccounts)
                {
                }
            }
        }
    }

    var
        SelectionOptionsQst: Label 'Intercompany accounts,Current company accounts,Both';
        MapAccountsInstructionQst: Label 'For which of the following tables do you want to perform the mapping?';
        RemoveMappingInstructionQst: Label 'For which of the following tables do you want to remove the mapping?';
}