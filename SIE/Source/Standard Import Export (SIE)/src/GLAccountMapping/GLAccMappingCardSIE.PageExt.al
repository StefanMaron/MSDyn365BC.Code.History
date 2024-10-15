#if not CLEAN24
pageextension 5317 "G/L Acc. Mapping Card SIE" extends "G/L Account Mapping Card"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This page was replaced by the G/L Account Mapping Card SIE page';
    ObsoleteTag = '24.0';

    layout
    {
        modify(StandardAccountCategoryNo)
        {
            Enabled = false;
            Visible = false;
        }
    }
}
#endif