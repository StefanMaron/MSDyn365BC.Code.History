enum 1800 "Company Setup Status"
{
    Extensible = false;

    /// <summary>
    /// Undefined.
    /// </summary>
    value(0; " ")
    {
    }

    /// <summary>
    /// Setup completed.
    /// </summary>
    value(1; Completed)
    {
    }

    /// <summary>
    /// Setup is in progress.
    /// </summary>
    value(2; "In Progress")
    {
    }

    /// <summary>
    /// Setup ended in an error.
    /// </summary>
    value(3; Error)
    {
    }

    /// <summary>
    /// The user performing setup is missing permissions.
    /// </summary>
    value(4; "Missing Permission")
    {
    }
}