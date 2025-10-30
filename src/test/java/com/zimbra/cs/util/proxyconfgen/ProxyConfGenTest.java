package com.zimbra.cs.util.proxyconfgen;

import static org.junit.jupiter.api.Assertions.*;

import java.io.File;
import org.apache.logging.log4j.Level;
import org.apache.logging.log4j.Logger;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

// TODO: missing LDAP connection
class ProxyConfGenTest {

	private static LdapEnvironment ldapEnvironment;

	@BeforeAll
	static void setUpBeforeClass() throws Exception {
		ldapEnvironment = new LdapEnvironment();
		ldapEnvironment.setup();
	}

	@AfterAll
	static void tearDownAfterClass() throws Exception {
		ldapEnvironment.tearDown();
	}

	@Test
	void shouldUseOverrideTemplatePathWhenOverrideConditionMatches() {
		File exampleTemplateFile = new File(ProxyConfGen.mTemplateDir + "/nginx.conf.web.http.default");
		final String overrideTemplateFilePath =
				ProxyConfGen.OVERRIDE_TEMPLATE_DIR + File.separator + exampleTemplateFile.getName();
		final String templateFilePath =
				ProxyConfGen.getTemplateFilePath(exampleTemplateFile, overrideTemplateFilePath, true);
		assertEquals(
				ProxyConfGen.OVERRIDE_TEMPLATE_DIR + "/nginx.conf.web.http.default", templateFilePath);
	}

	@Test
	void shouldUseDefaultTemplatePathWhenOverrideConditionDoNotMatches() {
		File exampleTemplateFile = new File(ProxyConfGen.mTemplateDir + "/nginx.conf.web.http.default");
		final String overrideTemplateFilePath =
				ProxyConfGen.OVERRIDE_TEMPLATE_DIR + File.separator + exampleTemplateFile.getName();
		final String templateFilePath =
				ProxyConfGen.getTemplateFilePath(exampleTemplateFile, overrideTemplateFilePath, false);
		assertEquals(ProxyConfGen.mTemplateDir + "/nginx.conf.web.http.default", templateFilePath);
	}

	@Test
	void shouldLogInfoByDefault() throws Exception {
		ProxyConfGen.run(new String[]{""});
		final Logger rootLogger = org.apache.logging.log4j.LogManager.getRootLogger();
		Assertions.assertEquals(Level.INFO, rootLogger.getLevel());
	}

	@Test
	void shouldLogDebugWhenVerbose() throws Exception {
		ProxyConfGen.run(new String[]{"-v"});
		final Logger rootLogger = org.apache.logging.log4j.LogManager.getRootLogger();
		Assertions.assertEquals(Level.DEBUG, rootLogger.getLevel());
	}
}
