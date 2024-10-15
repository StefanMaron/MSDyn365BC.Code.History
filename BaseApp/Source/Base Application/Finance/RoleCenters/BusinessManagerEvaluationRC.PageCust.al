namespace Microsoft.Finance.RoleCenters;

pagecustomization "Business Manager Evaluation RC" customizes "Business Manager Role Center"
{
    layout
    {
        modify(Control9)
        {
            Visible = false;
        }

        modify("User Tasks Activities")
        {
            Visible = false;
        }

        modify(Emails)
        {
            Visible = false;
        }

        modify(ApprovalsActivities)
        {
            Visible = false;
        }

        modify(Control46)
        {
            Visible = false;
        }

        modify("Favorite Accounts")
        {
            Visible = false;
        }
    }

    actions
    {
    }
}