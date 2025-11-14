package com.zimbra.cs.util.proxyconfgen;

import com.zimbra.cs.account.ldap.LdapProvisioning;
import com.zimbra.cs.ldap.LdapClient;

public class TestLdapProvisioning extends LdapProvisioning {

	public TestLdapProvisioning(LdapClient ldapClient)  {
		super(CacheMode.OFF, ldapClient);
	}
}
