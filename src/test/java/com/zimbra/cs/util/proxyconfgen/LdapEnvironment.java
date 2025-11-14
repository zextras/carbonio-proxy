package com.zimbra.cs.util.proxyconfgen;

import com.google.common.collect.Maps;
import com.zextras.mailbox.util.InMemoryLdapServer;
import com.zextras.mailbox.util.InMemoryLdapServer.Builder;
import com.zimbra.common.localconfig.LC;
import com.zimbra.cs.account.Provisioning;
import com.zimbra.cs.ldap.LdapClient;
import com.zimbra.cs.ldap.unboundid.UBIDLdapClient;
import com.zimbra.cs.ldap.unboundid.UBIDLdapPoolConfig;

public class LdapEnvironment {

	private static InMemoryLdapServer inMemoryLdapServer;

	public void setup() throws Exception {
		final int ldapPort = PortUtil.findFreePort();
		LC.ldap_port.setDefault(1389);
		inMemoryLdapServer = new Builder()
				.withLdapPort(1389)
				.build();
		inMemoryLdapServer.start();
		inMemoryLdapServer.initializeBasicData();
		final UBIDLdapPoolConfig poolConfig = UBIDLdapPoolConfig.createNewPool(true);
		final UBIDLdapClient client = UBIDLdapClient.createNew(poolConfig);
		LdapClient.setInstance(client);
		Provisioning.setInstance(new TestLdapProvisioning(client));
		final Provisioning provisioning = Provisioning.getInstance();
		provisioning.createServer("localhost", Maps.newHashMap());
	}

	public void tearDown() {
		inMemoryLdapServer.shutDown(true);
		Provisioning.setInstance(null);
		LdapClient.shutdown();
	}

}
